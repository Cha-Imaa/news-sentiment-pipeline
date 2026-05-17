# News Sentiment Analytics Pipeline

An end-to-end AWS data engineering project that ingests news articles, stores raw data in a relational database, transforms the data using AWS Glue, writes analytics-ready Parquet datasets to Amazon S3, catalogs them with AWS Glue Crawler, queries them with Amazon Athena, and visualizes insights in a Jupyter notebook.

## Project Objective

The goal of this project is to simulate a real-world cloud data pipeline used for analytics. The pipeline starts with raw news article data and produces structured sentiment analytics that can be queried and visualized.

## Architecture Overview

The pipeline follows this flow:

```text
Kaggle CSV Dataset
        ↓
Python Loader Script
        ↓
Amazon RDS MySQL
        ↓
AWS Glue ETL Job
        ↓
Amazon S3 Data Lake
        ↓
AWS Glue Crawler
        ↓
Amazon Athena
        ↓
Jupyter Notebook Analytics