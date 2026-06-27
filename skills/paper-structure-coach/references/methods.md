# Methods

Core principle: **reproducibility**. A reader should be able to exactly replicate the study based solely on this section. Err on the side of too much detail.

## Structure

Organize chronologically with clear subheadings. Recommended subsections:

### 1. Problem Formalization
- Governing equations, boundary/initial conditions, loss function (if ML-based)
- Reference standard formulations rather than rederiving from scratch
- Keep symbols consistent throughout the paper — define each symbol once here

### 2. Method Description
- Mathematical or algorithmic framework, design choices justified with citations
- Avoid "as previously described" shortcut citations unless the cited source is: (a) detailed and reusable, (b) describes the exact method used, and (c) is Open Access (per PRO-MaP 2024)
- Text recycling is acceptable — reuse exact method descriptions from prior work with attribution

### 3. Experimental Configuration
- **Data**: source, preprocessing, train/validation/test split
- **Hyperparameters**: all tunable parameters with search ranges
- **Metrics**: definition, rationale for each metric
- **Hardware/software**: GPU/CPU specs, framework versions, random seed ranges

## Statistical Reporting Standards

| Item | Requirement |
|------|-------------|
| **Replicates** | Report how many times each experiment was performed. **Biological ≠ technical replicates** — distinguish clearly |
| **Sample size** | State whether a power analysis was used. If not, explain how N was determined |
| **Randomization** | State whether samples were randomized; specify the method |
| **Blinding** | State whether experimenters were blinded to group assignment |
| **Exclusion criteria** | Clearly state criteria for data/subject exclusion |
| **Statistics** | Report exact N, central tendency (mean/median), dispersion (SD/SEM), confidence intervals, and exact p-values (not just "p < 0.05") |
| **Ablation** | Describe ablation setup clearly — what was removed/changed and why |

## Materials Availability

- Provide company names, catalog numbers, and RRIDs (Research Resource Identifiers) for all commercial reagents, antibodies, cell lines, and software
- Deposit unique materials (plasmids, cell lines, code, trained models) in public repositories (Addgene, protocols.io, GitHub, Zenodo, Hugging Face)
- Include a **Code Availability** statement and a **Data Availability** statement at the end of Methods

## Constraints
- Cite rather than rewrite published method descriptions (but avoid shortcut citations — write enough for independent replication)
- Keep symbols consistent throughout the manuscript
- **No result statements** in Methods — results belong in Results section
- Use **past tense** for completed procedures; **passive voice** is traditional but active voice ("We trained…") is increasingly accepted
