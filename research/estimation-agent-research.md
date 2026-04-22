# Research Report: AI Estimation Agent System (RFP → Odhad)

**Cíl:** Shromáždit podklady pro návrh multi-agent systému, který z RFP
(typicky PDF v češtině) vyprodukuje strukturovaný odhad pracnosti, složení
týmu, rizika a otevřené otázky.

---

## TL;DR

1. **Architektura:** orchestrator-worker pattern (Anthropic) s 1 primary
   agentem (`estimator`) a 2–3 specializovanými subagenty (`requirements-extractor`,
   `wbs-planner`, `risk-analyst`). Lead model = Opus-třída, workers = Sonnet-třída.
   Očekávej ~15× token overhead oproti single-agent, ale výrazně lepší kvalitu
   na složitých úlohách (Anthropic: +90,2 % na research úlohách).
2. **Skills jako nosič expertízy:** každý subagent dostane vlastní `SKILL.md`
   s *progressive disclosure* (metadata → SKILL.md <5k tokenů → resources bez
   limitu). Doménové znalosti (PERT tabulky, role-rate karty, šablony WBS,
   antipatterns) patří do `resources/`, ne do promptu.
3. **Matematika odhadu:** PERT trojbodový odhad
   `TE = (O + 4M + P) / 6`, `σ = (P − O) / 6`. Součet napříč WBS položkami s
   odmocninou součtu rozptylů (CLT) dává realistický interval spolehlivosti.
   Pro malé týmy doplnit Wideband Delphi (konsensus) místo jednoho odhadce.
4. **Struktura WBS:** dodržet *100 % rule* a MECE (Mutually Exclusive,
   Collectively Exhaustive), hloubka ~3 úrovně, listová položka 8–80 hodin
   (80-hour rule). Role breakdown: Analýza, BE, FE, QA, DevOps, PM, Design.
5. **Extrakce z PDF:** `pdfplumber` pro strukturovaný text + tabulky,
   `pdftotext -layout` jako fallback. Pro naskenovaná PDF OCR (`tesseract -l ces`).
   Česká diakritika vyžaduje UTF-8 pipeline end-to-end a font-aware extrakci.

---

## 1. Anthropic Skills — design principy

Zdroje:
- <https://www.anthropic.com/news/skills>
- <https://docs.claude.com/en/docs/agents-and-tools/agent-skills/overview>
- <https://github.com/anthropics/skills>

### Klíčové principy

**Skill = složka** s povinným souborem `SKILL.md` (YAML frontmatter + Markdown
instrukce) a volitelnými `resources/`, `scripts/`, `references/`.

**Progressive disclosure ve 3 úrovních:**

| Úroveň | Co se načítá | Velikost | Kdy |
|---|---|---|---|
| 1. Metadata | `name` + `description` z frontmatteru | ~100 tokenů | Vždy při startu |
| 2. SKILL.md body | Plný obsah `SKILL.md` | < 5 000 tokenů | Když model rozhodne, že skill je relevantní |
| 3. Resources | Další soubory (PDF, CSV, kód, šablony) | Neomezené | On-demand přes file tools |

### Struktura `SKILL.md`

```markdown
---
name: estimation-pert
description: Produces three-point (PERT) effort estimates with confidence
  intervals for software work breakdown items. Use when the user provides
  a list of tasks and asks for hours, days, or cost ranges.
---

# Instructions
...
```

- `description` musí obsahovat *kdy* skill použít — je to jediné, co model
  vidí při rozhodování o aktivaci.
- `SKILL.md` má být stručný; detailní tabulky, příklady a data patří do
  `resources/` (lazy-loaded).

### Doporučení pro RFP → odhad

Vhodní kandidáti na skills v našem systému:

1. **`rfp-pdf-extraction`** — extrakce textu z českých PDF (resources:
   `extract.py` s `pdfplumber`, fallback `pdftotext`).
2. **`requirements-invest-moscow`** — klasifikace requirementů (resources:
   INVEST checklist, MoSCoW šablona, příklady).
3. **`estimation-pert`** — trojbodový odhad (resources: tabulky role-rate,
   kalkulátor `pert.py`, vzorové WBS).
4. **`wbs-templates`** — knihovna WBS šablon pro typické zakázky (web app,
   mobile, integrace, data pipeline).
5. **`risk-catalog`** — katalog typických rizik + mitigation (resources:
   `risks.yaml`).

---

## 2. Multi-agent orchestration pattern

Zdroj: <https://www.anthropic.com/engineering/built-multi-agent-research-system>

### Orchestrator-worker pattern

- **Lead agent** (orchestrator) plánuje, dekomponuje problém na subtasks,
  spouští workery paralelně, agreguje výsledky.
- **Subagents** (workers) běží v izolovaných kontextech, každý s jedním
  zaměřeným úkolem a vlastními nástroji.
- **Kontext-izolace** je klíčová: worker nevidí celý RFP ani ostatní workery —
  jen svůj zúžený brief. To zabraňuje *context pollution* a umožňuje
  paralelismus.

### Paralelní vs sekvenční

| Paralelní | Sekvenční |
|---|---|
| Nezávislé úlohy (4 scannery, 4 sekce PRD) | Úlohy s dependencies (extract → analyze → estimate) |
| Rychlejší wall-clock | Nižší token spotřeba |
| Vyšší komplexita synchronizace | Jednodušší error handling |

Anthropic měří, že multi-agent systém spotřebuje **~15× více tokenů** než
jednoduchý chat. Používat jen tam, kde paralelizace nebo specializace přináší
reálnou hodnotu.

### Lessons learned (vybrané z 8)

1. **"Think like your agents"** — iteruj prompty pozorováním skutečného
   chování, ne jen čtením výstupu.
2. **Explicitní rozpočty** — říkej workerovi kolik toolcallů a jakou hloubku
   search smí dělat; jinak přestřelí.
3. **End-state evals** — testuj finální výstup, ne mezi-kroky; agenti najdou
   jiné cesty ke správnému řešení.
4. **Lead model volba** — Opus pro orchestraci (potřebuje dlouhé plánování),
   Sonnet pro workery (rychlost + cena).

### Aplikace na estimation systém

```
estimator (primary, Opus)
  ├─> requirements-extractor (Sonnet, paralelní per sekce RFP)
  ├─> wbs-planner (Sonnet, sekvenční po extraktoru)
  └─> risk-analyst (Sonnet, paralelní s wbs-planner)
```

---

## 3. Estimation framework

### 3.1 PERT (trojbodový odhad)

Zdroj: <https://en.wikipedia.org/wiki/Three-point_estimation>

Pro každou WBS položku zadej 3 hodnoty:

- **O** (Optimistic) — best case, ~1 % pravděpodobnost rychlejšího
- **M** (Most likely) — modus
- **P** (Pessimistic) — worst case realistic

**Vzorce:**

```
TE (Expected)        = (O + 4M + P) / 6
σ  (Std deviation)   = (P − O) / 6
Var                  = σ²
```

**Agregace napříč WBS (při nezávislosti položek):**

```
TE_total = Σ TE_i
σ_total  = √(Σ σ_i²)   # ne Σ σ_i!
```

**Intervaly spolehlivosti (normální aproximace):**

| Interval | Pokrytí |
|---|---|
| TE ± 1σ | ~68 % |
| TE ± 1,645σ | 90 % |
| TE ± 2σ | ~95 % |
| TE ± 3σ | ~99,7 % |

### 3.2 Work Breakdown Structure

Zdroj: <https://en.wikipedia.org/wiki/Work_breakdown_structure>

**Pravidla:**

- **100 % rule** — součet child elementů = 100 % práce parent elementu. Nic
  víc, nic míň.
- **MECE** — Mutually Exclusive, Collectively Exhaustive; žádné překryvy.
- **Deliverable-oriented**, ne activity-oriented (popisuj *co*, ne *jak*).
- **80-hour rule** — listová položka má být 8–80 hodin práce. Větší = rozlož
  dál, menší = agreguj.
- **Hloubka** — typicky 3–4 úrovně. Víc vede k micromanagementu.

### 3.3 Role breakdown (typická SW zakázka)

| Role | Default % z dev effort | Pozn. |
|---|---|---|
| Analýza / PO | 10–15 % | Víc pro nejasné RFP |
| Backend | 30–45 % | |
| Frontend | 20–35 % | Null pro API-only |
| QA | 15–25 % | Min. 15 % i u MVP |
| DevOps / Infra | 5–15 % | Víc pro on-prem / regulated |
| PM / Delivery | 10–15 % | Scale s délkou projektu |
| Design / UX | 5–15 % | Jen pokud není dodán |

### 3.4 Buffery

- **Contingency buffer** (known unknowns): +15–25 % na TE_total.
- **Management reserve** (unknown unknowns): +10–15 %, drží PM/sponsor.
- **Neschovávej buffery do odhadů položek** — ztratí se transparentnost a
  Parkinsonův zákon je sní.

### 3.5 Story points vs person-days

| | Story points | Person-days |
|---|---|---|
| Jednotka | Relativní (komplexita) | Absolutní (čas) |
| Vhodné pro | Interní plánování sprintu | Externí nabídky, smlouvy |
| Stabilita | Nezávisí na složení týmu | Závisí na seniority |
| RFP → odhad | ❌ klient nechápe | ✅ převoditelné na cenu |

**Doporučení:** agent produkuje **person-days + hodinovou sazbu per role**.
Story points interně jen jako mezikrok, ne v outputu.

### 3.6 COCOMO (referenční)

Zdroj: <https://en.wikipedia.org/wiki/COCOMO>

```
Effort = a · (KSLOC)^b · EAF
```

- Organic (a=2.4, b=1.05), Semi-detached (3.0, 1.12), Embedded (3.6, 1.20)
- EAF = součin 15 cost driverů (RELY, DATA, CPLX, TIME, STOR, …)

Pro RFP → odhad je COCOMO **sekundární sanity-check**, ne primární metoda
(vyžaduje odhad KSLOC, což je na úrovni RFP nemožné). Použitelné jen pro
hrubé order-of-magnitude srovnání.

### 3.7 Wideband Delphi

Zdroj: <https://en.wikipedia.org/wiki/Wideband_delphi>

Boehm & Farquhar, 1970s. Konsensuální odhad v týmu:

1. Kickoff — moderátor představí problém, WBS.
2. Individuální odhady (anonymní).
3. Diskuse rozptylu (kdo odhadl extrém, proč).
4. Re-estimate. Opakuj, dokud rozptyl neklesne pod práh.

**V AI systému:** simuluj jako *N paralelních estimator subagentů s různou
persona/seniority* → agregace v orchestrátoru → druhé kolo s flagovanými
outliery. Ekvivalent Delphi bez lidí.

---

## 4. Requirements & use case extraction

### INVEST (pro user stories)

| Písmeno | Význam |
|---|---|
| **I**ndependent | Lze realizovat samostatně |
| **N**egotiable | Není smlouva, ale námět na diskusi |
| **V**aluable | Přináší hodnotu uživateli / byznysu |
| **E**stimable | Tým dokáže odhadnout |
| **S**mall | Sedí do sprintu |
| **T**estable | Má jasné acceptance criteria |

V estimation agentu: requirement, který selže v **E** nebo **T**, jde
automaticky do *open-questions* bucketu, ne do WBS.

### MoSCoW (prioritizace)

- **Must have** — bez toho projekt selže (→ baseline estimate)
- **Should have** — důležité, ale obejitelné (→ optional scope)
- **Could have** — nice-to-have (→ separate line item)
- **Won't have (this time)** — explicitně vyloučeno (→ out-of-scope log)

Agent má MoSCoW nutně produkovat i když RFP prioritizaci neuvádí — odvozuje ji
z jazyka ("musí", "měl by", "lze zvážit").

---

## 5. Open questions / ambiguity detection

Agent **musí** vracet seznam otevřených otázek. Heuristiky pro detekci:

1. **Modální slovesa bez subjektu** — "systém by měl umět" bez definice
   rozsahu/výkonu/uživatele.
2. **Kvantifikátory bez čísel** — "rychle", "mnoho uživatelů",
   "dostatečně škálovatelné".
3. **Nedefinované integrace** — zmínka systému třetí strany bez
   API/dokumentace/credentials.
4. **Chybějící NFR** — žádný údaj o výkonu, dostupnosti, security,
   compliance.
5. **Konflikty v textu** — jedna sekce říká "cloud", jiná "on-premise".
6. **Chybějící akceptační kritéria** — requirement bez definice "hotovo".
7. **Vague verbs** — "integrovat", "zefektivnit", "optimalizovat" bez metriky.

Každá otevřená otázka má: `kontext (citace z RFP)`, `proč je to problém`,
`dopad na odhad (± X MD)`, `navrhovaná odpověď/assumption`.

---

## 6. PDF extraction (česká diakritika)

### Nástroje

| Nástroj | Use case | Diakritika |
|---|---|---|
| `pdfplumber` (Python) | Strukturovaný text + tabulky | ✅ UTF-8 native |
| `pdftotext -layout` (poppler) | Rychlý fallback, zachová layout | ✅ s `-enc UTF-8` |
| `pymupdf` / `fitz` | Rychlý, dobrý na komplexní layouty | ✅ |
| `tesseract -l ces` | OCR pro scany | ⚠️ jen s českým jazykovým balíčkem |
| `unstructured` | Hybrid, dobře na heterogenní dokumenty | ✅ |

### Best practices

1. **Detekuj typ PDF** — `pdfplumber` extract textu → pokud délka < threshold,
   je to scan, přepni na OCR.
2. **UTF-8 end-to-end** — `open(f, encoding="utf-8")`, `subprocess` s
   `text=True, encoding="utf-8"`.
3. **Normalizace Unicode** — `unicodedata.normalize("NFC", text)` pro sjednocení
   kombinovaných znaků (á vs a + ◌́).
4. **Tabulky zvlášť** — `pdfplumber.extract_tables()`, neházej je do flat textu;
   RFP často obsahují tabulky scopu a požadavků.
5. **Header/footer stripping** — opakující se text na každé stránce zahluší
   LLM signal.
6. **Zachovej pozice** — strana + bounding box pro citace v open-questions.

### Minimální pipeline

```python
import pdfplumber, unicodedata
pages = []
with pdfplumber.open(path) as pdf:
    for i, p in enumerate(pdf.pages, 1):
        text = p.extract_text() or ""
        text = unicodedata.normalize("NFC", text)
        tables = p.extract_tables()
        pages.append({"page": i, "text": text, "tables": tables})
```

---

## 7. MUST-HAVE checklist

Estimation agent **musí** pro každý RFP produkovat:

- [ ] **Shrnutí RFP** (5–10 bullet pointů, čemu rozumí)
- [ ] **Seznam requirementů** s MoSCoW klasifikací
- [ ] **WBS** (deliverable-oriented, 100% rule, 80-hour rule, hloubka ≤ 4)
- [ ] **PERT odhad per položka** (O, M, P, TE, σ)
- [ ] **Agregovaný odhad** (TE_total, σ_total, 90% CI)
- [ ] **Role breakdown** (MD per role)
- [ ] **Předpoklady** (assumptions, explicitně vypsané)
- [ ] **Open questions** (strukturované, s dopadem na odhad)
- [ ] **Rizika** (top 5–10, s pravděpodobností a dopadem)
- [ ] **Buffery** (contingency + management reserve, transparentně)
- [ ] **Out-of-scope** (explicitně vyloučené položky)
- [ ] **Audit trail** — každá WBS položka má odkaz na zdroj v RFP (strana +
      citace). Bez této vazby odhad není obhajitelný.

---

## 8. NICE-TO-HAVE

- **Několik scénářů** — MVP / Standard / Full (3 varianty scope).
- **Sensitivity analysis** — "co se stane s odhadem, když integrace X padne".
- **Porovnání s historickými projekty** (vyžaduje DB minulých odhadů).
- **Confidence score per položka** (low/med/high) — doplňuje σ.
- **Architektonický náčrt** (C4 Context + Container level) pro validaci
  rozumnosti WBS. Zdroj: <https://c4model.com/>
- **arc42-inspired structure** pro dokument technického návrhu, pokud ho agent
  taky generuje. Zdroj: <https://arc42.org/overview>
- **Gantt/timeline** z WBS + závislostí.
- **Cash-flow projekce** (MD × sazba × distribuce v čase).

---

## 9. Antipatterns (čeho se vyvarovat)

1. **Jeden bodový odhad** bez intervalu ("projekt stojí 1 200 MD") — vždy
   dávej rozsah.
2. **Schované buffery v položkách** — znemožňuje ex-post kalibraci.
3. **Odhad bez WBS** — LLM má tendenci vyplivnout číslo bez dekompozice. Forsuj
   WBS jako povinný mezi-krok.
4. **Požadavky = WBS položky 1:1** — requirementy jsou *co*, WBS je *jak*.
5. **Ignorování open questions** — agent, který nic nezpochybní, není
   důvěryhodný. Zero open questions = red flag.
6. **Activity-oriented WBS** ("schůzky", "psaní kódu") místo
   deliverable-oriented ("přihlašovací modul", "API reportů").
7. **Optimistický bias** — M ~ O. Forsuj, aby P − O bylo alespoň 30 % M.
8. **Chybějící role DevOps/QA** — LLM je často "zapomene". Šablona role
   breakdown musí být povinný input.
9. **Story points klientovi** — nepřevoditelné na fakturu.
10. **Single-shot prompt** — narvat celý RFP + "odhadni" do jednoho volání.
    Ztrácí se auditovatelnost i kvalita.
11. **Context pollution** — worker, který vidí víc, než potřebuje, se rozptyluje.
12. **Chybějící verifikace** — žádná kontrola, že součet WBS = 100 % scope.
    Agent musí explicitně validovat 100% rule.

---

## 10. Doporučená architektura

### High-level

```
┌─────────────────────────────────────────────────────────────┐
│  User: "Odhadni RFP v tomto PDF"                            │
└───────────────────┬─────────────────────────────────────────┘
                    ▼
        ┌───────────────────────┐
        │  estimator (primary)  │  Opus-class
        │  - orchestrace        │
        │  - validace 100% rule │
        │  - agregace PERT      │
        │  - final output       │
        └───┬─────────┬─────────┘
            │         │         │
   ┌────────▼──┐  ┌───▼──────┐  ┌▼────────────┐
   │requirements│  │   wbs-   │  │    risk-    │
   │ -extractor │  │  planner │  │   analyst   │
   │  (Sonnet)  │  │ (Sonnet) │  │  (Sonnet)   │
   └────────────┘  └──────────┘  └─────────────┘
        │              │               │
   ┌────▼──────────────▼───────────────▼────┐
   │  Shared skills (progressive disclosure)│
   │  • rfp-pdf-extraction                  │
   │  • requirements-invest-moscow          │
   │  • estimation-pert                     │
   │  • wbs-templates                       │
   │  • risk-catalog                        │
   └────────────────────────────────────────┘
```

### Agent responsibilities

**1. `estimator` (primary, tab-cycleable)**
- Vstup: cesta k PDF + kontext od uživatele.
- Krok 1: spustí `rfp-pdf-extraction` skill → strukturovaný text.
- Krok 2: dispatchuje 3 subagenty (requirements paralelně, pak wbs + risk
  paralelně).
- Krok 3: validuje 100% rule a MECE na WBS.
- Krok 4: agreguje PERT (TE_total, σ_total), aplikuje buffery.
- Krok 5: produkuje finální odhad dokument.
- **HIL checkpoint** po extrakci requirementů (před WBS) — uživatel
  odsouhlasí/doplní.

**2. `requirements-extractor` (subagent)**
- Vstup: čistý text RFP + skill `requirements-invest-moscow`.
- Výstup: seznam requirementů s MoSCoW + INVEST flagy + citace (strana).
- Ambiguity flagging (heuristiky ze sekce 5).

**3. `wbs-planner` (subagent)**
- Vstup: schválené requirementy + skill `wbs-templates`.
- Výstup: WBS se 100% rule validací + PERT 3-point per položka + role
  breakdown.
- **Interně Wideband-Delphi simulace**: 3 paralelní odhady s různou personou
  (optimista, realista, pesimista) → konsensus.

**4. `risk-analyst` (subagent)**
- Vstup: requirementy + WBS + skill `risk-catalog`.
- Výstup: top 5–10 rizik s P/I maticí a mitigation.
- Doporučení buffer velikosti.

### Handoff formáty (Beads-style nebo JSON)

```json
{
  "requirement_id": "R-012",
  "text": "Systém umožní export dat do CSV.",
  "moscow": "Must",
  "invest_flags": {"estimable": false},
  "source": {"page": 7, "quote": "...export do běžných formátů..."},
  "open_questions": ["Jaké formáty kromě CSV?", "Velikost exportu?"]
}
```

```json
{
  "wbs_id": "2.3.1",
  "title": "CSV export endpoint (BE)",
  "requirement_ids": ["R-012"],
  "role": "BE",
  "pert": {"O": 2, "M": 4, "P": 8, "TE": 4.33, "sigma": 1.0},
  "confidence": "medium"
}
```

### Proč právě 3 subagenti (ne víc, ne míň)

- **Méně než 3** (např. jen extractor + planner): ztráta specializace, risk
  analýza splyne s WBS a bude odbytá.
- **Více než 3** (samostatný architect, qa-strategist, cost-estimator): režie
  orchestrace a token cost převáží benefit. Na RFP → odhad 3 role pokrývají
  INVEST dimenze: *co* (requirements), *jak + kolik* (wbs), *co může
  selhat* (risk).

---

## Zdroje

### Úspěšně načtené

1. Anthropic — Skills announcement
   <https://www.anthropic.com/news/skills>
2. Anthropic — Agent Skills overview (docs)
   <https://docs.claude.com/en/docs/agents-and-tools/agent-skills/overview>
3. Anthropic — Skills repository (příklady)
   <https://github.com/anthropics/skills>
4. Anthropic — How we built our multi-agent research system
   <https://www.anthropic.com/engineering/built-multi-agent-research-system>
5. Wikipedia — Three-point estimation (PERT)
   <https://en.wikipedia.org/wiki/Three-point_estimation>
6. Wikipedia — Work breakdown structure
   <https://en.wikipedia.org/wiki/Work_breakdown_structure>
7. Wikipedia — COCOMO
   <https://en.wikipedia.org/wiki/COCOMO>
8. Wikipedia — Wideband Delphi
   <https://en.wikipedia.org/wiki/Wideband_delphi>
9. C4 Model
   <https://c4model.com/>
10. arc42 overview
    <https://arc42.org/overview>

### Neúspěšně načtené (fallback na obecné znalosti)

- PMI — Estimating techniques (403 Forbidden)
  <https://www.pmi.org/learning/library/estimating-techniques-projects-8790>
- Google search (JS-required, nepoužitelné pro fetch)

### Označení `[general knowledge]`

Následující tvrzení nejsou přímo podložena fetchnutými zdroji a vycházejí z
obecných znalostí oboru (měla by být ověřena před produkčním nasazením):

- Konkrétní procentuální rozložení rolí v sekci 3.3 (BE 30–45 %, QA 15–25 %
  atd.) — orientační, vychází z běžné praxe SW house, ne z citovaného zdroje.
- Hodnoty bufferu 15–25 % / 10–15 % — běžná praxe PM, ne přímo z PMI zdroje
  (který se nepodařilo načíst).
- PDF extraction best practices (sekce 6) — syntéza běžné praxe; dokumentace
  `pdfplumber`/`pdftotext` nebyla v tomto research cyklu fetchnuta.
- Heuristiky pro ambiguity detection (sekce 5) — syntéza INVEST + běžné
  praxe, ne přímá citace.
