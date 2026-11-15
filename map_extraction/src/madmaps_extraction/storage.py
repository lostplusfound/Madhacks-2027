"""Optional append-only Delta history, with a typed envelope and VARIANT payload."""

import json
import re


def persist(payload, table, *, record_type):
    if not re.fullmatch(
        r"[A-Za-z_][A-Za-z0-9_]*\.[A-Za-z_][A-Za-z0-9_]*\.[A-Za-z_][A-Za-z0-9_]*", table
    ):
        raise ValueError(
            "Delta table must be catalog.schema.table using simple identifiers"
        )
    from pyspark.sql import SparkSession
    from pyspark.sql import functions as F

    spark = SparkSession.builder.getOrCreate()
    quoted = ".".join(f"`{part}`" for part in table.split("."))
    spark.sql(f"""CREATE TABLE IF NOT EXISTS {quoted} (
        record_id STRING, record_type STRING, created_at TIMESTAMP, payload VARIANT
    ) USING DELTA""")
    from uuid import uuid4

    spark.createDataFrame(
        [(uuid4().hex, record_type, json.dumps(payload, allow_nan=False))],
        "record_id STRING, record_type STRING, json STRING",
    ).select(
        "record_id",
        "record_type",
        F.current_timestamp().alias("created_at"),
        F.expr("parse_json(json)").alias("payload"),
    ).write.mode("append").saveAsTable(table)
