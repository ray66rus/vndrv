-- 
-- Created by SQL::Translator::Producer::MySQL
-- Created on Sun Jan 17 13:03:16 2016
-- 
SET foreign_key_checks=0;

DROP TABLE IF EXISTS afisha;

--
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

DROP TABLE IF EXISTS clips;

--
-- Table: clips
--
CREATE TABLE clips (
  caption_id varchar(32) NOT NULL,
  clip4 text NULL,
  story_id bigint NOT NULL,
  clip1 text NULL,
  clip3 text NULL,
  clip5 text NULL,
  issue_id bigint NOT NULL,
  block_id bigint NOT NULL,
  id integer NOT NULL auto_increment,
  clip2 text NULL,
  time timestamp NOT NULL,
  INDEX issue_id_idx (issue_id),
  INDEX story_id_idx (story_id),
  INDEX block_id_idx (block_id),
  INDEX caption_id_idx (caption_id),
  PRIMARY KEY (id),
  UNIQUE path (issue_id, story_id, block_id, caption_id)
) DEFAULT CHARACTER SET UTF8;

DROP TABLE IF EXISTS compare;

--
-- Table: compare
--
CREATE TABLE compare (
  id integer NOT NULL auto_increment,
  text5 text NULL,
  name5 text NULL,
  caption_id varchar(32) NOT NULL,
  foto2 text NULL,
  name1 text NULL,
  name2 text NULL,
  story_id bigint NOT NULL,
  name3 text NULL,
  foto4 text NULL,
  foto1 text NULL,
  foto5 text NULL,
  block_id bigint NOT NULL,
  text4 text NULL,
  title text NULL,
  text1 text NULL,
  text3 text NULL,
  time timestamp NOT NULL,
  text2 text NULL,
  foto3 text NULL,
  name4 text NULL,
  issue_id bigint NOT NULL,
  INDEX issue_id_idx (issue_id),
  INDEX story_id_idx (story_id),
  INDEX block_id_idx (block_id),
  INDEX caption_id_idx (caption_id),
  PRIMARY KEY (id),
  UNIQUE path (issue_id, story_id, block_id, caption_id)
) DEFAULT CHARACTER SET UTF8;

DROP TABLE IF EXISTS ecocols;

--
-- Table: ecocols
--
CREATE TABLE ecocols (
  num6 integer NULL,
  id integer NOT NULL auto_increment,
  text5 text NULL,
  num5 integer NULL,
  story_id bigint NOT NULL,
  caption_id varchar(32) NOT NULL,
  num4 integer NULL,
  num1 integer NULL,
  text6 text NULL,
  text3 text NULL,
  text1 text NULL,
  header text NULL,
  text4 text NULL,
  block_id bigint NOT NULL,
  time timestamp NOT NULL,
  num2 integer NULL,
  num3 integer NULL,
  text2 text NULL,
  issue_id bigint NOT NULL,
  INDEX issue_id_idx (issue_id),
  INDEX story_id_idx (story_id),
  INDEX block_id_idx (block_id),
  INDEX caption_id_idx (caption_id),
  PRIMARY KEY (id),
  UNIQUE path (issue_id, story_id, block_id, caption_id)
) COLLATE utf8_general_ci;

DROP TABLE IF EXISTS ecorows;

--
-- Table: ecorows
--
CREATE TABLE ecorows (
  text2 text NULL,
  num3 integer NULL,
  num7 integer NULL,
  num2 integer NULL,
  issue_id bigint NOT NULL,
  block_id bigint NOT NULL,
  text1 text NULL,
  header text NULL,
  text4 text NULL,
  text3 text NULL,
  time timestamp NOT NULL,
  num4 integer NULL,
  caption_id varchar(32) NOT NULL,
  story_id bigint NOT NULL,
  num5 integer NULL,
  text6 text NULL,
  num1 integer NULL,
  text7 text NULL,
  id integer NOT NULL auto_increment,
  num6 integer NULL,
  text5 text NULL,
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
  news2 text NULL,
  time timestamp NOT NULL,
  foto5 text NULL,
  block_id bigint NOT NULL,
  title text NULL,
  issue_id bigint NOT NULL,
  foto3 text NULL,
  title2 text NULL,
  id integer NOT NULL auto_increment,
  foto4 text NULL,
  foto1 text NULL,
  news1 text NULL,
  caption_id varchar(32) NOT NULL,
  foto2 text NULL,
  news5 text NULL,
  news3 text NULL,
  news4 text NULL,
  story_id bigint NOT NULL,
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
  r_03 text NULL,
  num_l_02 text NULL,
  id integer NOT NULL auto_increment,
  foto1 text NULL,
  story_id bigint NOT NULL,
  caption_id varchar(32) NOT NULL,
  foto2 text NULL,
  l_02 text NULL,
  num_r_02 text NULL,
  time timestamp NOT NULL,
  num_r_03 text NULL,
  l_01 text NULL,
  block_id bigint NOT NULL,
  header text NULL,
  r_02 text NULL,
  l_03 text NULL,
  issue_id bigint NOT NULL,
  num_l_01 text NULL,
  num_l_03 text NULL,
  num_r_01 text NULL,
  score_r text NULL,
  r_01 text NULL,
  score_l text NULL,
  INDEX issue_id_idx (issue_id),
  INDEX story_id_idx (story_id),
  INDEX block_id_idx (block_id),
  INDEX caption_id_idx (caption_id),
  PRIMARY KEY (id),
  UNIQUE path (issue_id, story_id, block_id, caption_id)
) DEFAULT CHARACTER SET UTF8;

SET foreign_key_checks=1;

