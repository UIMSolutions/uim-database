# UIM HANA Cloud (MVP)

An educational, in-memory HTAP database server inspired by SAP HANA Cloud, implemented with **Dlang** and **vibe.d**, and structured with a lightweight `uim-framework` layer.

## Implemented capabilities (MVP)

- In-memory computing
- Columnar data storage
- Real-time analytics + transactional writes (HTAP pattern)
- Data types: numeric, bool, text, timestamp, JSON, spatial point
- Text search (inverted index)
- Graph data (adjacency graph + path lookup)
- Built-in predictive library (PAL-style linear regression)
- Python/R execution bridge for model scoring scripts
- Data virtualization (CSV federation)
- High availability/security primitives (API key auth + replication log endpoint)

## Run

```bash
dub run
```

Server defaults:

- Host: `0.0.0.0`
- Port: `8080`
- API key: `dev-secret-key`

## Key endpoints

- `POST /api/v1/tables`
- `POST /api/v1/rows/:table`
- `POST /api/v1/query/select`
- `POST /api/v1/query/aggregate`
- `POST /api/v1/text/index`
- `POST /api/v1/text/search`
- `POST /api/v1/graph/edge`
- `POST /api/v1/graph/path`
- `POST /api/v1/spatial/within-radius`
- `POST /api/v1/ml/pal/linear/train`
- `POST /api/v1/ml/pal/linear/predict`
- `POST /api/v1/integration/python/run`
- `POST /api/v1/integration/r/run`
- `POST /api/v1/virtualization/csv/query`
- `GET /api/v1/ha/status`
- `POST /api/v1/ha/replicate`

## Notes

This project is an MVP architecture and not a production-complete SAP HANA replacement.
