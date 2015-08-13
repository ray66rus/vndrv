package DB::CGSchema;

# based on the DBIx::Class Schema base class
use base qw/DBIx::Class::Schema/;

use FindBin;

our $VERSION = 0.9;

__PACKAGE__->load_namespaces();
__PACKAGE__->load_components(qw/Schema::Versioned/);
__PACKAGE__->upgrade_directory("$FindBin::Bin/../migrations/cg");

1;
