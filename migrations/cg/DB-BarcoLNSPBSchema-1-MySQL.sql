-- 
-- Created by SQL::Translator::Producer::MySQL
-- Created on Fri Sep 25 00:51:12 2015
-- 
SET foreign_key_checks=0;

DROP TABLE IF EXISTS compare;

--
-- Table: compare
--
CREATE TABLE compare (
  text4 text NULL,
  text1 text NULL,
  name1 text NULL,
  foto1 text NULL,
  title text NULL,
  foto4 text NULL,
  story_id bigint NOT NULL,
  text5 text NULL,
  name5 text NULL,
  foto3 text NULL,
  text3 text NULL,
  time timestamp NOT NULL,
  name3 text NULL,
  id integer NOT NULL auto_increment,
  issue_id bigint NOT NULL,
  name4 text NULL,
  name2 text NULL,
  block_id bigint NOT NULL,
  caption_id varchar(32) NOT NULL,
  foto5 text NULL,
  text2 text NULL,
  foto2 text NULL,
  INDEX issue_id_idx (issue_id),
  INDEX story_id_idx (story_id),
  INDEX block_id_idx (block_id),
  INDEX caption_id_idx (caption_id),
  PRIMARY KEY (id),
  UNIQUE path (issue_id, story_id, block_id, caption_id)
) DEFAULT CHARACTER SET UTF8;

DROP TABLE IF EXISTS news;

--
-- Table: news
--
CREATE TABLE news (
  story_id bigint NOT NULL,
  title2 text NULL,
  title text NULL,
  news1 text NULL,
  block_id bigint NOT NULL,
  caption_id varchar(32) NOT NULL,
  news3 text NULL,
  issue_id bigint NOT NULL,
  news4 text NULL,
  foto text NULL,
  id integer NOT NULL auto_increment,
  time timestamp NOT NULL,
  news5 text NULL,
  news2 text NULL,
  INDEX issue_id_idx (issue_id),
  INDEX story_id_idx (story_id),
  INDEX block_id_idx (block_id),
  INDEX caption_id_idx (caption_id),
  PRIMARY KEY (id),
  UNIQUE path (issue_id, story_id, block_id, caption_id)
) COLLATE utf8_general_ci;

SET foreign_key_checks=1;
