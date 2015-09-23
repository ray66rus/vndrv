package VNDRV::Connector::CG::Caspar;

use Moose;

use DB::CasparCGSchema;

extends 'VNDRV::Connector::CG';

has 'data' => (is => 'ro', isa => 'DB::CasparCGSchema::Result::Main');

sub _db_drv_info {
	return {schema => 'DB::CasparCGSchema', name => 'Pg', options => { pg_utf8_strings => 1 }};
}

sub _get_time_field_value {
	my $self = shift;
	my $time = shift;
	return \"to_timestamp($time)";
}

1;
