-- 
-- Created by SQL::Translator::Producer::MySQL
-- Created on Sun Jan 17 13:03:16 2016
-- 
SET foreign_key_checks=0;

DROP TABLE IF EXISTS afisha;

-- Table: afisha
--
CREATE TABLE afisha (
  header text NULL,
  block_id bigint NOT NULL,
  time text NULL,
  foto3 text NULL,
  day text NULL,
  issue_id bigint NOT NULL,
  id integer NOT NULL auto_increment,
  foto2 text NULL,
  place2 text NULL,
  subheader3 text NULL,
  caption_id varchar(32) NOT NULL,
  color text NULL,
  place1 text NULL,
  story_id bigint NOT NULL,
  foto1 text NULL,
  subheader2 text NULL,
  subheader1 text NULL,
  INDEX issue_id_idx (issue_id),
  INDEX story_id_idx (story_id),
  INDEX block_id_idx (block_id),
  INDEX caption_id_idx (caption_id),
  PRIMARY KEY (id),
  UNIQUE path (issue_id, story_id, block_id, caption_id)
) DEFAULT CHARACTER SET UTF8;

SET foreign_key_checks=1;

