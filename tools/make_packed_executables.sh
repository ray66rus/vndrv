#!/bin/bash

carton exec pp -a lib/ -M Moose -M List::MoreUtils::PP -M Modern::Perl -M SQL::Translator -o bin/deploydb bin/deploydb.pl
