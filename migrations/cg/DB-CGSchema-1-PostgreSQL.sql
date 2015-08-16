-- 
-- Created by SQL::Translator::Producer::PostgreSQL
-- Created on Sun Aug 16 17:33:13 2015
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
  issue_slug text,
  story_id bigint NOT NULL,
  story_slug text,
  block_id bigint NOT NULL,
  block_slug text,
  PRIMARY KEY (id),
  CONSTRAINT path UNIQUE (issue_id, story_id, block_id)
);
CREATE INDEX issue_id_idx on news_data (issue_id);
CREATE INDEX story_id_idx on news_data (story_id);
CREATE INDEX block_id_idx on news_data (block_id);
CREATE INDEX timestamp_idx on news_data (last);

