-- 
-- Created by SQL::Translator::Producer::PostgreSQL
-- Created on Wed Sep 23 14:05:17 2015
-- 
--
-- Table: news_data
--
DROP TABLE news_data CASCADE;
CREATE TABLE news_data (
  id serial NOT NULL,
  last timestamp with time zone NOT NULL,
  captions json,
  issue_id bigint NOT NULL,
  issue_name text,
  issue_start timestamp with time zone,
  story_id bigint NOT NULL,
  story_name text,
  block_id bigint NOT NULL,
  block_name text,
  PRIMARY KEY (id),
  CONSTRAINT path UNIQUE (issue_id, story_id, block_id)
);
CREATE INDEX issue_id_idx on news_data (issue_id);
CREATE INDEX story_id_idx on news_data (story_id);
CREATE INDEX block_id_idx on news_data (block_id);
CREATE INDEX timestamp_idx on news_data (last);

