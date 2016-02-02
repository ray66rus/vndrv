package VNDRV::Connector::Redis;

use Encode qw(decode encode);
use Moose;
use Redis;
use JSON;

extends 'VNDRV::Connector';

sub BUILD {
	my $self = shift;
	
	my $data_redis_addr = $self->config->{data_redis_address};
	my $message_redis_addr = $self->config->{message_redis_address};

	$self->{data_redis} = Redis->new;
	$self->{message_redis} = Redis->new(server => '127.0.0.1:6380');
}

sub _process_changes {
	my $self = shift;
	my $changes = shift;
	
	my $r = $self->{data_redis};
	my $rm = $self->{message_redis};
	
	#my ($v1, $v2) = $r->scan(0, MATCH => "i*", COUNT => 1000);
	
	#print Data::Dumper->Dump([$v2]);
	
	#start transaction
	$rm->multi();
	$r->multi();
	print "Transaction started\n";
	my $changed_issues = $changes->{issues};
	for my $i_id (keys %$changed_issues) 
	{
		if (!$changed_issues->{$i_id})
		{
			$r->srem("issues", $i_id);
			$r->del("i:".$i_id.":stories");
			$r->del("i:".$i_id.":data");
			next;
		}
		$rm->publish("upd:i:".$i_id, $i_id); #TODO: what do the message contain?
		$r->sadd("issues", $i_id);
		$self->_process_issue_changes($i_id, $changed_issues->{$i_id});
	}
	$r->exec();
	$rm->exec();
	print "Transaction ended";
	#end transaction
	
	#my $issue = $self->get_issue({issue => "6"});
	#print Data::Dumper->Dump([$changes]);
}

sub _process_issue_changes {
	my $self = shift;
	my $i_id = shift;
	my $issue_delta = shift;
	my $r = $self->{data_redis};
	my $rm = $self->{message_redis};
	
	eval {
		for my $issue_field_name (keys %$issue_delta)
		{
			if ($issue_field_name eq "stories")
			{
				my $changed_stories = $issue_delta->{stories};
				for my $story_id (keys %$changed_stories)
				{
					if (!$changed_stories->{$story_id})
					{
						$r->srem("i:".$i_id.":stories", $story_id);
						$r->del("s:".$story_id.":blocks");
						$r->del("s:".$story_id.":data");
						$r->del("s:".$story_id.":parent");
						next;
					}
					$rm->publish("upd:s:".$story_id, $story_id);
					$r->sadd("i:".$i_id.":stories", $story_id);
					$self->_process_story_changes({
							issue_id => $i_id,
							story_id => $story_id,
							story_delta => $changed_stories->{$story_id}});
				}
			}
			else
			{
				$r->hset("i:".$i_id.":data", $issue_field_name, Encode::encode('UTF-8', $issue_delta->{$issue_field_name}{new}, Encode::FB_CROAK));
			}
		}	
	};
	$self->log->error("NUD0020E Error while updating issue $i_id: $@")
		if $@;
}

sub _process_story_changes {
	my $self = shift;
	my $params = shift;

	my ($i_id, $s_id, $story_delta) =
		($params->{issue_id}, $params->{story_id}, $params->{story_delta});
	my $r = $self->{data_redis};
	my $rm = $self->{message_redis};
	
	eval {
		$r->set("s:".$s_id.":parent", $i_id);
		for my $story_field_name (keys %$story_delta)
		{
			if ($story_field_name eq "blocks")
			{
				my $changed_blocks = $story_delta->{blocks};
				for my $block_id (keys %$changed_blocks)
				{
					if (!$changed_blocks->{$block_id})
					{
						$r->srem("s:".$s_id.":blocks", $block_id);
						$r->del("b:".$block_id.":data");
						$r->del("b:".$block_id.":parent");
						$r->del("b:".$block_id.":c");
						next;
					}
					
					$rm->publish("upd:b:".$block_id, $block_id);
					$r->sadd("s:".$s_id.":blocks", $block_id);
					$self->_process_block_changes({
							issue_id => $i_id,
							story_id => $s_id,
							block_id => $block_id,
							block_delta => $changed_blocks->{$block_id}});
				}
			}
			else
			{
				next if ($story_field_name eq "id");
				$r->hset("s:".$s_id.":data", $story_field_name, Encode::encode('UTF-8', $story_delta->{$story_field_name}{new}, Encode::FB_CROAK));				
			}
		}
	};
	$self->log->error("NUM0021E Error while updating story $s_id: $@")
		if $@;
}

sub _process_block_changes {
	my $self = shift;
	my $params = shift;

	my ($i_id, $s_id, $b_id, $block_delta) =
		($params->{issue_id}, $params->{story_id}, $params->{block_id}, $params->{block_delta});
	my $r = $self->{data_redis};
	
	eval {
		$r->set("b:".$b_id.":parent", $s_id);
		for my $block_field_name (keys %$block_delta)
		{
			next if ($block_field_name eq "id");
			my $value = $block_delta->{$block_field_name}{"new"}; #TODO: seems that Encode::encode corrupt its args 
			$r->hset("b:".$b_id.":data", $block_field_name, Encode::encode('UTF-8', $value, Encode::FB_CROAK));	
			 
			if ($block_field_name eq "text")
			{
				#print Data::Dumper->Dump([$self->_get_captions($block_delta->{$block_field_name}{"new"})]);
				
				$self->_process_capt_changes({
							issue_id => $i_id,
							story_id => $s_id,
							block_id => $b_id,
							block_delta => $block_delta});
			
				
				#my @capts = $self->_get_captions($block_delta->{$block_field_name}{new});
				#if (scalar(@capts))
				#{
					#$r->set("b:".$b_id.":c", encode_json \@capts);
					#my $captId = 1; 
					#foreach my $capt (@capts)
					#{
					#	$value = $capt->{"type"};
					#	$r->set("b:".$b_id.":c:".$captId.":t", Encode::encode('UTF-8', $value, Encode::FB_CROAK));
					#	my $fields = $capt->{"fields"};
					#	foreach my $key (keys %$fields)
					#	{
					#		$value = $fields->{$key};
					#		$r->hset("b:".$b_id.":c:".$captId.":f", Encode::encode('UTF-8', $key, Encode::FB_CROAK), Encode::encode('UTF-8', $value, Encode::FB_CROAK));
					#	}
					#	$captId++;
					#}
				#}
			}
		}
	};
	$self->log->error("NUM0022E Error!!! while updating block $b_id: $@")
		if $@;
}

sub _process_capt_changes {
	my $self = shift;
	my $params = shift;

	my ($i_id, $s_id, $b_id, $block_delta) =
		($params->{issue_id}, $params->{story_id}, $params->{block_id}, , $params->{block_delta});
	my $r = $self->{data_redis};
	
	my @capts = $self->_get_captions($block_delta->{"text"}{new});
	return if (!scalar(@capts));
	
	my @oldCapts;
	if (defined($block_delta->{"text"}{old}))
	{
		@oldCapts = $self->_get_captions($block_delta->{"text"}{old});
	}
	
	#check deleted capts
	foreach my $oldCapt (@oldCapts)
	{
		my $oldId = sprintf("%x%x", $b_id, $oldCapt->{id});
		my $deleted = 1;
		foreach my $capt (@capts)
		{
			my $newId = sprintf("%x%x", $b_id, $capt->{id});
			if ($capt->{id} eq $oldId)
			{
				$deleted = 0;
				last; 
			}  
		}
		
		if ($deleted == 1)
		{
			$r->zrem("s:".$s_id.":capts", $oldId);
		}
	}
	
	my $count = 1;
	foreach my $capt (@capts)
	{	
		my $captId = sprintf("%x%x", $b_id, $capt->{id});
		print "ID is ".$captId."\n";
		my $value = $captId;
		
		if (defined($block_delta->{"position"}))
		{
			my $pos = $block_delta->{"position"}{new}*100 + $count;
			$r->zadd("s:".$s_id.":capts", $pos, Encode::encode('UTF-8', $value, Encode::FB_CROAK));
		}
		 
		$count++;
		
		if (defined($block_delta->{"active"}))
		{
			$value = $block_delta->{"active"}{new};
			$r->hset("c:".$captId.":data", "active", Encode::encode('UTF-8', $value, Encode::FB_CROAK));
		}
				
		$value = $capt->{"type"};
		$r->hset("c:".$captId.":data", "type", Encode::encode('UTF-8', $value, Encode::FB_CROAK));
		my $fields = $capt->{"fields"};
		foreach my $key (keys %$fields)
		{
			$value = $fields->{$key};
			$r->hset("c:".$captId.":fields", Encode::encode('UTF-8', $key, Encode::FB_CROAK), Encode::encode('UTF-8', $value, Encode::FB_CROAK));
		}
	}
			
}

1;
