# WasteWise Tools

## Training Dataset Export

`training_dataset_export.py` builds a frozen, reproducible dataset bundle from
offline JSONL exports of `training_candidates` and `training_labels`.

Dry run:

```bash
python3 tools/training_dataset_export.py \
  --candidates-jsonl exports/training_candidates.jsonl \
  --labels-jsonl exports/training_labels.jsonl \
  --dataset-version waste-v0.1 \
  --out datasets/waste-v0.1 \
  --dry-run
```

Write bundle:

```bash
python3 tools/training_dataset_export.py \
  --candidates-jsonl exports/training_candidates.jsonl \
  --labels-jsonl exports/training_labels.jsonl \
  --dataset-version waste-v0.1 \
  --out datasets/waste-v0.1
```

Outputs:

- `manifest.jsonl`
- `labels.jsonl`
- `datasheet.md`

Default exclusions:

- no explicit training consent
- revoked/deleted candidates
- rejected or PII-flagged candidates
- redaction not passed
- unreviewed candidates unless `--allow-unreviewed` is set
