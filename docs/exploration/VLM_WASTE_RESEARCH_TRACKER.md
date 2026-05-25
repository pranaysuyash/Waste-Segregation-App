# VLM-for-Waste Research Tracker

**Status**: Exploration doc — quarterly literature scan
**Last Updated**: 2026-05-25
**Category**: Industry Signal
**Parent**: [EXPLORATION_TOPICS.md](../EXPLORATION_TOPICS.md#a24-vlm-for-waste-research-frontier--industry-signal-)
**Related**: Eval Harness & Golden Sets (#5), Multi-Model AI Routing (#1), On-Device Inference (#6), Classification Confidence (#2), Model Lifecycle (A4)

---

## Why This Is a Topic

Vision-Language Models (VLMs) for waste classification are an active research frontier, not a settled technology. Published results shift quarterly. Without a systematic tracker, the app risks (a) investing in a technique that the research community has already surpassed, or (b) missing a breakthrough that could fundamentally change the architecture.

This doc is a **living tracker** — updated quarterly with new papers, accuracy claims, and reproducibility assessments.

---

## Current Landscape (2026-05-25)

### Key Finding

The convergence of three independent studies (Malla et al., Novelis, MDPI Sensors) in 2025 demonstrates that **prompt engineering + small model selection beats heavy retraining** for waste classification. This is now a measured discipline, not a vibes exercise.

### Published Claims-to-Evidence Map

| Paper/Source | Date | Claim | Evidence Quality | Reproducible? |
|---|---|---|---|---|
| Malla et al., Waste Management 204 | Jul 2025 | Targeted prompting raises VLM zero-shot accuracy by 9.4% to 90.48%; supervised fine-tuning to 97.18% | High — peer-reviewed, published methodology | Yes — uses TrashNet variant |
| Novelis, "Comparative Analysis of VLMs for Scalable Waste Recognition" | Dec 2025 | OpenCLIP ViT L/14 reaches ~82-90% zero-shot; fine-tuning with 15 images/class reaches ~97% | Medium-High — white paper with benchmarking against public dataset | Yes — uses Kumsetty et al. (2022) dataset |
| MDPI Sensors 2025 | Jul 2025 | Integrated sensor + VLM fusion improves classification robustness | Medium — hardware-specific, less generalizable | Partially — dependent on sensor setup |
| OpenCLIP benchmarks (ongoing) | — | Larger ViT encoders consistently outperform smaller ones for waste | High — reproducible on public benchmarks | Yes |

### What the Research Tells Us

1. **Zero-shot accuracy ceiling**: ~82-90% for unoptimized prompts, ~90%+ with prompt engineering — usable for the common case, insufficient for safety-critical categories
2. **Fine-tuning returns**: 15 labelled images per class reaches ~97% — small dataset requirement means the app's correction data could quickly bootstrap a fine-tuned model
3. **Model size matters**: 3B-8B parameter VLMs (Gemma 3n class) are viable for on-device deployment, but large ViT encoders (L/14-2B class) still outperform smaller ones
4. **Edge inference speed**: Optimized CLIP-based architectures achieve ~263 FPS (3.79ms/image) on modern edge hardware — sufficient for real-time classification at sorting line speeds

### Research Frontier Gaps (What's Not Published)

- **Dirty/obscured items**: Most published benchmarks use clean lab images — real-world performance on crushed, dirty, or low-light items is under-studied
- **Multi-object cluttered scenes**: Single-object classification dominates the literature; multi-item detection + classification for waste is rare
- **Regional rule integration**: No published work on combining VLM classification with regional disposal rule application
- **User correction feedback**: Using consumer corrections as training signal is discussed theoretically but not benchmarked

---

## Quarterly Scan Cadence

### What to Track Each Quarter

| Domain | What to Monitor | Frequency | Source |
|--------|----------------|-----------|--------|
| VLM accuracy improvements | New models, benchmarks, waste-specific fine-tuning | Quarterly | arXiv, Waste Management, MDPI Sensors |
| On-device inference viability | New small VLMs, quantization libraries, edge benchmarks | Quarterly | CVPR, NeurIPS workshops, TFLite/MediaPipe releases |
| Prompt engineering | Template innovations, class-specific prompting | Semi-annual | PapersWithCode, waste-specific conferences |
| Competitive intelligence | Competitor app accuracy claims | Quarterly | App store reviews, competitor blogs, white papers |
| DPP / regulatory | EU DPP mandate progress, GS1 Digital Link adoption | Semi-annual | EU Commission, industry consortium updates |

### Quarterly Scan Procedure

1. Search arXiv / Google Scholar for "waste classification VLM" and "waste recognition vision language model"
2. Check MDPI Sensors, Waste Management (Elsevier), Journal of Cleaner Production for new waste-AI papers
3. Review Novelis, Greyparrot, AMP Robotics blogs for industry updates
4. Update the claims-to-evidence map
5. Assess whether any new result changes the app's architecture recommendation
6. File a brief update to this doc (no more than 1 page of new findings + architecture implications)

---

## Implications for App Architecture

### Confirmed (no change needed quarterly)

- Eval harness (#5) should surface prompt-version A/B results as a first-class artefact — this is the most leveraged use of research findings
- 3B–8B VLMs remain viable for on-device tier without unacceptable accuracy loss
- Fine-tuning with 15 images/class is achievable from the correction data pipeline

### Watch for Change

- If a new small VLM (sub-3B) achieves >90% zero-shot accuracy on a waste benchmark, the on-device tier priority moves from "experiment" to "build"
- If any published result shows >95% zero-shot accuracy on dirty/obscured items, re-evaluate the cloud-first default path
- If a competitor publishes verified >95% consumer-accuracy at scale, the bar for the eval harness moves up

### Assessment Methodology

When a new claim is published, assess against:
1. Does it use a **public, reproducible benchmark** (TrashNet, Kumsetty, or the app's own golden set)?
2. Does the accuracy hold across **waste categories** (not just plastics or just organics)?
3. Is the model **deployable on the app's minimum target device** (mid-tier Android, iPhone 12)?
4. Does the technique **generalize to dirty/real-world items**, not just lab-prepared samples?

---

## Open Questions

- Should the app publish a benchmark (using its golden set) to establish a baseline for the field? This would increase credibility and attract research partnerships.
- Is there value in a waste-VLM-specific academic collaboration (e.g., sponsoring a student thesis on VLM waste classification with real-world data)?
- How should the tracker interact with the model lifecycle (A4) — should new models be added to the "watch" column of the model registry based on the quarterly scan?
