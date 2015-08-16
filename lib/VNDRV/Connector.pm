package VNDRV::Connector;

use Moose;
use threads;

use JSON::XS;
use LWP::UserAgent;
use HTTP::Cookies;
use Data::Dumper;

use utf8;

my $SOT_PATTERN = 'ВА';
my $CAP_PATTERN = 'ГР';
my $CAP_TYPE_PATTERN = 'Тип титра';

has 'changes' => (is => 'ro', isa => 'Thread::Queue');
has 'rd' => (is => 'ro', isa => 'HashRef');
has 'feedback' => (is => 'ro', isa => 'Thread::Queue');
has 'is_application_running' => (is => 'ro', isa => 'ScalarRef');
has 'log' => (is => 'ro', isa => 'Log::Handler');
has 'config' => (is => 'ro', isa => 'HashRef');

has 'json' => (is => 'ro', isa => 'JSON::XS', default => sub { my $json = JSON::XS->new; $json->allow_nonref; return $json });
has 'ua' => (is => 'ro', isa => 'LWP::UserAgent', default => sub { my $ua = LWP::UserAgent->new; $ua->cookie_jar(HTTP::Cookies->new); return $ua });

sub run {
	my $self = shift;

	my $name = ref($self);
	$self->log->info("NUD0010I $name connector started");

	$self->_set_stop_thread_signal_handler;
	eval {	
		while(!$self->_is_terminated) {
			if(defined(my $changes = $self->changes->dequeue_timed(1))) {
				$self->_process_changes($changes);
			}
		}
	};
	$self->log->error("NUD0011E Critical error in $name connector: $@")
		if($@);
	$self->log->debug("NUD0012I Exit from $name connector thread");
}

sub _set_stop_thread_signal_handler {
	my $self = shift;
	$SIG{STOP} = sub { threads->exit };
}

sub _is_terminated {
	my $self = shift;
	return (${$self->is_application_running} == 1) ? 0 : 1;
}

sub get_issue {
	my $self = shift;
	my $path = shift;

	lock(%{$self->rd});
	my $issue = $self->rd->{issues}{$path->{issue}};
	return $issue ? $self->_copy_from_shared($issue) : '';
}

sub _copy_from_shared {
	my $self = shift;
	my $data = shift;

	my $ref = ref($data);
	if($ref eq 'HASH') {
		return $self->_copy_hash_from_shared($data);
	} elsif($ref eq 'ARRAY') {
		return $self->_copy_array_from_shared($data);
	} elsif($ref eq 'SCALAR') {
		return $self->_copy_scalar_from_shared($data);
	} elsif(!$ref) {
		return $data;
	}
	return undef;
}

sub _copy_hash_from_shared {
	my $self = shift;
	my $hsh = shift;

	my %res = ();
	$res{$_} = $self->_copy_from_shared($hsh->{$_}) for (keys %$hsh);
	return \%res;
}

sub _copy_array_from_shared {
	my $self = shift;
	my $arr = shift;

	my @res = ();
	push @res, $self->_copy_from_shared($_) for @$arr;
	return \@res;
}

sub _copy_scalar_from_shared {
	my $self = shift;
	my $sclr = shift;
	return $self->_copy_from_shared($$sclr);
}

sub get_story {
	my $self = shift;
	my $path = shift;

	lock(%{$self->rd});
	my $story = '';
	eval {
		my $issue = $self->rd->{issues}{$path->{issue}};
		$story = $issue->{stories}{$path->{story}};
	};
	return $story ? $self->_copy_from_shared($story) : '';
}

sub get_block {
	my $self = shift;
	my $path = shift;

	lock(%{$self->rd});
	my $block = '';
	eval {
		my $issue = $self->rd->{issues}{$path->{issue}};
		my $story = $issue->{stories}{$path->{story}};
		$block = $story->{blocks}{$path->{btock}};
	};
	return $block ? $self->_copy_from_shared($block) : '';
}

sub send_feedback {
	my $self = shift;
	my $feedback = shift;
	$self->feedback->enqueue($feedback);
}

sub _are_captions_updated {
	my $self = shift;
	my $delta = shift;

	my $old_captions = $self->_get_captions_as_strings($delta->{text}{old} // '');
	my $new_captions = $self->_get_captions_as_strings($delta->{text}{new});
	return ($old_captions eq $new_captions) ? 0 : 1;
}

sub _get_captions_as_strings {
	my $self = shift;
	my $text = _vn_text_unescape(shift);
	return join('', $self->_get_captions_as_array($text));
}

sub _get_captions_as_array {
	my $self = shift;
	my $text = shift;

	my @captions = ();
	my $nodes_list = _vn_parse_string_nocontext($text, sub { return $_[0] }, 1);
	for my $node (@$nodes_list) {
		next
			if(length($node) == 0);
		if($node =~ s/^\(\(\s*$SOT_PATTERN(.+?)\s*\)\)$/$1/is) {
			push @captions, $self->_get_captions_as_array($node);
		} elsif($node =~ s/^\(\(\s*$CAP_PATTERN(.+?)\s*\)\)$/$1/is) {
			push @captions, $node;
		}
	}
	return @captions;
}

sub _get_captions {
	my $self = shift;
	my $text = _vn_text_unescape(shift);
	my @captions = ();
	for my $caption_str ($self->_get_captions_as_array($text)) {
		my $caption = _make_caption_from_string($caption_str);
		push @captions, $caption
			if $caption;
	}
	return $self->json->encode(\@captions);
}

sub _vn_text_unescape {
	my $str = shift;

	$str =~ s/((\\\\)*)\\n/$1\n/g;
	$str =~ s/\\\\/\\/g;

	return $str;
}

sub _vn_parse_string_nocontext {
	my $text = shift;
	my $func = shift;

	my @buf = ();
	my @res = ();
	my $last = ($text =~ s/(\(+)$//s) ? $1 : '';
	my ($first, @blocks) = split(/\({2}/, $text);
	$res[0] = $first
		if defined($first);
	while(@blocks) {
		my $tmp = shift @blocks;
		if($tmp =~ s/^(.*?\){2})(.*)$/$2/s) {
			my $buf =  "(($1";
			while(@buf and $tmp =~ s/^(.*?\){2})(.*)$/$2/s) {
				$buf = (pop @buf) . "$buf$1";
			}
			if(!@buf) {
				push @res, &{$func}($buf);
				push @res, $tmp if($tmp ne '');
			} else {
				$buf[-1] .= &{$func}($buf) . $tmp;
			}
		} else {
			push @buf, "(($tmp";
		}
	}

	$buf[-1] .= $last if(@buf and $last);
	push @res, @buf;
	return \@res;
}

sub _make_caption_from_string {
	my $text = shift;

	$text =~ s/^\s*(?:(\d+\:\d+)|(\d+))?.*?\n//s;
	return undef
		unless($text =~ s/^\s*$CAP_TYPE_PATTERN\:[ \t]+(.*?)\s*$//m);

	my %caption = (type => $1);

	$text =~ s/^\s*ID:[ \t]*(.*?)\s*$//m;

	my @fields = ();
	my $current_field_id = '';
	$caption{fields} = {};
	while($text =~ s/^\s*(.+?)[ \t]*\:[ \t]*(.*?)\s*$//m) {
		if($1 ne $current_field_id) {
			$caption{fields}->{$current_field_id} = $fields[-1]
				if @fields;
			$current_field_id = $1;
			push @fields, $2;
		} else {
			$fields[-1] .= "\n$2";
		}
	}
	$caption{fields}->{$current_field_id} = $fields[-1]
		if @fields;

	return \%caption;
}

1;