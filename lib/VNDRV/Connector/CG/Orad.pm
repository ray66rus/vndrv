package VNDRV::Connector::CG::Orad;

use Moose;

use DB::OradCGSchema;

extends 'VNDRV::Connector::CG';

has 'db' => (is => 'ro', isa => 'Schema');
has 'data' => (is => 'ro', isa => 'DB::OradCGSchema::Result::Main');

sub BUILD {
	my $self = shift;

	my $db_config = $self->config->{db} // {};
	my $addr = $db_config->{addr};
	my $user = $db_config->{user};
	my $pass = $db_config->{pass};
	my $db_name = $db_config->{db_name} // 'news_data';

	$self->{db} = DB::OradCGSchema->connect("dbi:mysql:dbname=$db_name;host=$addr", $user, $pass, { mysql_enable_utf8 => 1 });

	$self->{data} = $self->{db}->resultset('Main');
	$self->data->delete_all;
	$self->data->create({issue_id => 0, story_id => 0, block_id => 0, last => \'NOW()'});
}

sub _get_time_field_value {
	my $self = shift;
	my $time = shift;
	return \"from_unixtime($time)";
}

1;
