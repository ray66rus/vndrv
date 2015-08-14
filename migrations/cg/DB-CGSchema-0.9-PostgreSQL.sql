-- 
-- Created by SQL::Translator::Producer::PostgreSQL
-- Created on Thu Aug 13 20:51:56 2015
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

