import sys
from datetime import datetime

from awsglue.context import GlueContext
from awsglue.job import Job
from awsglue.utils import getResolvedOptions
from pyspark.context import SparkContext
from pyspark.sql import functions as F
from pyspark.sql.types import StringType


args = getResolvedOptions(
    sys.argv,
    [
        "JOB_NAME",
        "connection_name",
        "database_name",
        "s3_output_path",
    ],
)

sc = SparkContext()
glue_context = GlueContext(sc)
spark = glue_context.spark_session

job = Job(glue_context)
job.init(args["JOB_NAME"], args)


def classify_sentiment(text):
    if text is None:
        return "neutral"

    text = text.lower()

    positive_words = [
        "good",
        "great",
        "excellent",
        "positive",
        "success",
        "win",
        "growth",
        "improve",
        "benefit",
        "strong",
    ]

    negative_words = [
        "bad",
        "poor",
        "negative",
        "fail",
        "loss",
        "decline",
        "risk",
        "crisis",
        "weak",
        "problem",
    ]

    positive_count = sum(1 for word in positive_words if word in text)
    negative_count = sum(1 for word in negative_words if word in text)

    if positive_count > negative_count:
        return "positive"

    if negative_count > positive_count:
        return "negative"

    return "neutral"


sentiment_udf = F.udf(classify_sentiment, StringType())


def write_parquet(df, path, partition_cols=None):
    writer = df.write.mode("overwrite").format("parquet")

    if partition_cols:
        writer = writer.partitionBy(*partition_cols)

    writer.save(path)


print("Reading articles table from RDS...")

articles_dynamic_frame = glue_context.create_dynamic_frame.from_options(
    connection_type="mysql",
    connection_options={
        "useConnectionProperties": "true",
        "dbtable": "articles",
        "connectionName": args["connection_name"],
    },
    transformation_ctx="articles_dynamic_frame",
)

articles_df = articles_dynamic_frame.toDF()

print(f"Loaded {articles_df.count()} articles from RDS.")

print("Cleaning and enriching article data...")

articles_clean_df = (
    articles_df
    .withColumn("article_id", F.col("id").cast("long"))
    .withColumn("published_date", F.to_date(F.col("published_at")))
    .withColumn("published_year", F.year(F.col("published_at")))
    .withColumn("published_month", F.month(F.col("published_at")))
    .withColumn("published_day", F.dayofmonth(F.col("published_at")))
    .withColumn(
        "article_text",
        F.concat_ws(
            " ",
            F.coalesce(F.col("title"), F.lit("")),
            F.coalesce(F.col("description"), F.lit("")),
            F.coalesce(F.col("content"), F.lit("")),
        ),
    )
    .withColumn("sentiment", sentiment_udf(F.col("article_text")))
    .withColumn("etl_loaded_at", F.lit(datetime.utcnow().isoformat()))
)

print("Creating date dimension...")

dim_date_df = (
    articles_clean_df
    .select(
        "published_date",
        "published_year",
        "published_month",
        "published_day",
    )
    .where(F.col("published_date").isNotNull())
    .dropDuplicates(["published_date"])
    .withColumnRenamed("published_date", "date_key")
)

print("Creating source dimension...")

dim_source_df = (
    articles_clean_df
    .select(
        F.coalesce(F.col("source_id"), F.lit("unknown")).alias("source_id"),
        F.coalesce(F.col("source_name"), F.lit("Unknown")).alias("source_name"),
    )
    .dropDuplicates(["source_id", "source_name"])
)

print("Creating article fact table...")

fact_articles_df = (
    articles_clean_df
    .select(
        F.col("article_id"),
        F.col("published_date").alias("date_key"),
        F.coalesce(F.col("source_id"), F.lit("unknown")).alias("source_id"),
        F.col("author"),
        F.col("title"),
        F.col("url"),
        F.col("sentiment"),
        F.col("published_year"),
        F.col("published_month"),
        F.col("etl_loaded_at"),
    )
)

s3_output_path = args["s3_output_path"].rstrip("/")

print(f"Writing dim_date to {s3_output_path}/dim_date/")
write_parquet(
    dim_date_df,
    f"{s3_output_path}/dim_date/",
)

print(f"Writing dim_source to {s3_output_path}/dim_source/")
write_parquet(
    dim_source_df,
    f"{s3_output_path}/dim_source/",
)

print(f"Writing fact_articles to {s3_output_path}/fact_articles/")
write_parquet(
    fact_articles_df,
    f"{s3_output_path}/fact_articles/",
    partition_cols=["published_year", "published_month"],
)

print("Glue ETL job completed successfully.")
job.commit()