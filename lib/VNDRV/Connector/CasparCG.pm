package VNDRV::Connector::CasparCG;

use Moose;

use DB::CGSchema;

extends 'VNDRV::Connector';

has 'db' => (is => 'ro', isa => 'Schema');

sub BUILD {
	my $self = shift;

	my $db_config = $self->config->{db} // {};
	my $addr = $db_config->{addr} // 'localhost';
	my $user = $db_config->{user} // 'mmp';
	my $pass = $db_config->{pass} // 'mmp';
	my $dbname = $db_config->{name} // 'news_data';

	$self->{db} = DB::CGSchema->connect("dbi:Pg:dbname=$dbname;host=$addr", $user, $pass);
}

sub _process_changes {
	my $self = shift;
	my $changes = shift;
}

1;
