package DB::BarcoLNSPBSchema::Result::News;

use Modern::Perl;
use base qw/DBIx::Class::Core/;

# Associated table in database
__PACKAGE__->table('news');

# Column definition
my %columns = (
	id => {
		data_type => 'integer',
		is_auto_increment => 1,
	},
	time => {
		data_type => 'timestamp'
	},
	issue_id => {
		data_type => 'bigint'
	},
	story_id => {
		data_type => 'bigint'
	},
	block_id => {
		data_type => 'bigint'
	},
	caption_id => {
		data_type => 'varchar(32)',
	},
	title => {
		data_type => 'text',
		is_nullable => 1,
	},
	title2 => {
		data_type => 'text',
		is_nullable => 1,
	}
);
for(my $i=1;$i<=5;$i++) {
	$columns{"news$i"} = { data_type => 'text', is_nullable => 1 };
	$columns{"foto$i"} = { data_type => 'text', is_nullable => 1 };
}

__PACKAGE__->add_columns(%columns);

# Tell DBIC  that 'id' is the primary key
__PACKAGE__->set_primary_key('id');
__PACKAGE__->add_unique_constraint('path' => [qw/issue_id story_id block_id caption_id/]);

sub sqlt_deploy_hook {
	my ($self, $sqlt_table) = @_;
	$sqlt_table->add_index(name => 'issue_id_idx', fields => ['issue_id']);
	$sqlt_table->add_index(name => 'story_id_idx', fields => ['story_id']);
	$sqlt_table->add_index(name => 'block_id_idx', fields => ['block_id']);
	$sqlt_table->add_index(name => 'caption_id_idx', fields => ['caption_id']);
	$sqlt_table->options({'CHARACTER SET' => 'UTF8', COLLATE => 'utf8_general_ci'});
}

1;
