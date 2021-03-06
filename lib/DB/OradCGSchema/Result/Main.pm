package DB::OradCGSchema::Result::Main;

use Modern::Perl;
use base qw/DBIx::Class::Core/;

# Associated table in database
__PACKAGE__->table('news_data');

# Column definition
__PACKAGE__->add_columns(
	id => {
		data_type => 'integer',
		is_auto_increment => 1,
	},
	last => {
		data_type => 'timestamp'
	},
	captions => {
		data_type => 'text',
		is_nullable => 1,
	},
	issue_id => {
		data_type => 'bigint'
	},
	issue_name => {
		data_type => 'text',
		is_nullable => 1,
	},
	issue_start => {
		data_type => 'datetime',
		is_nullable => 1,
	},
	story_id => {
		data_type => 'bigint'
	},
	story_name => {
		data_type => 'text',
		is_nullable => 1,
	},
	block_id => {
		data_type => 'bigint'
	},
	block_name => {
		data_type => 'text',
		is_nullable => 1,
	}
);

# Tell DBIC  that 'id' is the primary key
__PACKAGE__->set_primary_key('id');
__PACKAGE__->add_unique_constraint('path' => [qw/issue_id story_id block_id/]);

sub sqlt_deploy_hook {
	my ($self, $sqlt_table) = @_;
	$sqlt_table->add_index(name => 'issue_id_idx', fields => ['issue_id']);
	$sqlt_table->add_index(name => 'story_id_idx', fields => ['story_id']);
	$sqlt_table->add_index(name => 'block_id_idx', fields => ['block_id']);
	$sqlt_table->add_index(name => 'timestamp_idx', fields => ['last']);
	$sqlt_table->options({'CHARACTER SET' => 'UTF8', COLLATE => 'utf8_general_ci'});
}

1;
