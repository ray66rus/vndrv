package VNDRV::Connector::CG::Orad;

use Moose;

use DB::OradCGSchema;

extends 'VNDRV::Connector::CG';

has 'data' => (is => 'ro', isa => 'DB::OradCGSchema::Result::Main');

sub _db_drv_info {
	return {schema => 'DB::OradCGSchema', name => 'mysql', options => { mysql_enable_utf8 => 1 }};
}

sub _get_time_field_value {
	my $self = shift;
	my $time = shift;
	return \"from_unixtime($time)";
}

1;
