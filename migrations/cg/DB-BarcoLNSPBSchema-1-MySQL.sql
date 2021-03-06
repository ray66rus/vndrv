-- 
-- Created by SQL::Translator::Producer::MySQL
-- Created on Sun Jan 17 13:01:43 2016
-- 
SET foreign_key_checks=0;

DROP TABLE IF EXISTS clips;

--
-- Table: clips
--
CREATE TABLE clips (
  clip4 text NULL,
  clip1 text NULL,
  block_id bigint NOT NULL,
  caption_id varchar(32) NOT NULL,
  time timestamp NOT NULL,
  id integer NOT NULL auto_increment,
  clip3 text NULL,
  clip2 text NULL,
  clip5 text NULL,
  issue_id bigint NOT NULL,
  story_id bigint NOT NULL,
  INDEX issue_id_idx (issue_id),
  INDEX story_id_idx (story_id),
  INDEX block_id_idx (block_id),
  INDEX caption_id_idx (caption_id),
  PRIMARY KEY (id),
  UNIQUE path (issue_id, story_id, block_id, caption_id)
) COLLATE utf8_general_ci;

DROP TABLE IF EXISTS compare;

--
-- Table: compare
--
CREATE TABLE compare (
  foto5 text NULL,
  name3 text NULL,
  name4 text NULL,
  foto3 text NULL,
  foto1 text NULL,
  text1 text NULL,
  story_id bigint NOT NULL,
  name5 text NULL,
  foto2 text NULL,
  foto4 text NULL,
  text4 text NULL,
  caption_id varchar(32) NOT NULL,
  name2 text NULL,
  time timestamp NOT NULL,
  block_id bigint NOT NULL,
  text3 text NULL,
  text5 text NULL,
  name1 text NULL,
  title text NULL,
  id integer NOT NULL auto_increment,
  text2 text NULL,
  issue_id bigint NOT NULL,
  INDEX issue_id_idx (issue_id),
  INDEX story_id_idx (story_id),
  INDEX block_id_idx (block_id),
  INDEX caption_id_idx (caption_id),
  PRIMARY KEY (id),
  UNIQUE path (issue_id, story_id, block_id, caption_id)
) COLLATE utf8_general_ci;

DROP TABLE IF EXISTS ecocols;

--
-- Table: ecocols
--
CREATE TABLE ecocols (
  story_id bigint NOT NULL,
  num2 integer NULL,
  text1 text NULL,
  num1 integer NULL,
  num4 integer NULL,
  num5 integer NULL,
  header text NULL,
  num6 integer NULL,
  issue_id bigint NOT NULL,
  text2 text NULL,
  text6 text NULL,
  num3 integer NULL,
  id integer NOT NULL auto_increment,
  caption_id varchar(32) NOT NULL,
  time timestamp NOT NULL,
  block_id bigint NOT NULL,
  text5 text NULL,
  text3 text NULL,
  text4 text NULL,
  INDEX issue_id_idx (issue_id),
  INDEX story_id_idx (story_id),
  INDEX block_id_idx (block_id),
  INDEX caption_id_idx (caption_id),
  PRIMARY KEY (id),
  UNIQUE path (issue_id, story_id, block_id, caption_id)
) DEFAULT CHARACTER SET UTF8;

DROP TABLE IF EXISTS ecorows;

--
-- Table: ecorows
--
CREATE TABLE ecorows (
  num6 integer NULL,
  header text NULL,
  num5 integer NULL,
  num4 integer NULL,
  num1 integer NULL,
  text1 text NULL,
  num2 integer NULL,
  story_id bigint NOT NULL,
  text7 text NULL,
  text4 text NULL,
  text3 text NULL,
  text5 text NULL,
  block_id bigint NOT NULL,
  time timestamp NOT NULL,
  num7 integer NULL,
  caption_id varchar(32) NOT NULL,
  id integer NOT NULL auto_increment,
  num3 integer NULL,
  text6 text NULL,
  issue_id bigint NOT NULL,
  text2 text NULL,
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
  foto4 text NULL,
  foto2 text NULL,
  story_id bigint NOT NULL,
  foto5 text NULL,
  foto1 text NULL,
  foto3 text NULL,
  news3 text NULL,
  id integer NOT NULL auto_increment,
  title text NULL,
  news2 text NULL,
  title2 text NULL,
  news5 text NULL,
  news4 text NULL,
  issue_id bigint NOT NULL,
  news1 text NULL,
  block_id bigint NOT NULL,
  time timestamp NOT NULL,
  caption_id varchar(32) NOT NULL,
  INDEX issue_id_idx (issue_id),
  INDEX story_id_idx (story_id),
  INDEX block_id_idx (block_id),
  INDEX caption_id_idx (caption_id),
  PRIMARY KEY (id),
  UNIQUE path (issue_id, story_id, block_id, caption_id)
) COLLATE utf8_general_ci;

DROP TABLE IF EXISTS teams_compare;

--
-- Table: teams_compare
--
CREATE TABLE teams_compare (
  block_id bigint NOT NULL,
  score_l text NULL,
  caption_id varchar(32) NOT NULL,
  time timestamp NOT NULL,
  num_l_01 text NULL,
  num_l_03 text NULL,
  issue_id bigint NOT NULL,
  score_r text NULL,
  id integer NOT NULL auto_increment,
  l_02 text NULL,
  r_01 text NULL,
  foto1 text NULL,
  num_r_01 text NULL,
  l_03 text NULL,
  header text NULL,
  foto2 text NULL,
  story_id bigint NOT NULL,
  num_r_02 text NULL,
  l_01 text NULL,
  r_02 text NULL,
  r_03 text NULL,
  num_l_02 text NULL,
  num_r_03 text NULL,
  INDEX issue_id_idx (issue_id),
  INDEX story_id_idx (story_id),
  INDEX block_id_idx (block_id),
  INDEX caption_id_idx (caption_id),
  PRIMARY KEY (id),
  UNIQUE path (issue_id, story_id, block_id, caption_id)
) DEFAULT CHARACTER SET UTF8;

SET foreign_key_checks=1;

