package DB::CGSchema::Result::Main;

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
		data_type => 'timestamp with time zone'
	},
	captions => {
		data_type => 'json',
		is_nullable => 1,
	},
	issue_id => {
		data_type => 'bigint'
	},
	issue_slug => {
		data_type => 'text',
		is_nullable => 1,
	},
	story_id => {
		data_type => 'bigint'
	},
	story_slug => {
		data_type => 'text',
		is_nullable => 1,
	},
	block_id => {
		data_type => 'bigint'
	},
	block_slug => {
		data_type => 'text',
		is_nullable => 1,
	}
);

# Tell DBIC  that 'id' is the primary key
__PACKAGE__->set_primary_key('id');
__PACKAGE__->add_unique_constraint('path' => [qw/issue_id story_id block_id/]);

1;