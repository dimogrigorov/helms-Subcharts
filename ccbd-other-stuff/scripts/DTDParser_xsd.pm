package DTDParser_xsd;

use strict;

my $NAME_CHAR = '[\w\.\-\:]';
my $NAME = '[a-zA-Z\_\:]' . $NAME_CHAR . '*';
my $ATTR_NAME = $NAME;
my $ELEM_NAME = $NAME;
my $ETTY_NAME = $NAME;
my $TOKN_NAME = $NAME_CHAR . '+';
my $CONTENT_EMPTY = 'EMPTY';
my $CONTENT_PCDATA = '\(\s*\#PCDATA\s*\)';
my $CONTENT_ALT = '\(\s*' . $ELEM_NAME . '[\+]?(?:\s*\|\s*' . $ELEM_NAME
                  . '[\+]?)+\s*\)';
my $CONTENT_SEQ = '\(\s*(?:' . $ELEM_NAME . '|' . $CONTENT_ALT . ')[\?\+\*]?'
                  . '(?:\s*\,\s*(?:' . $ELEM_NAME . '|' . $CONTENT_ALT
                  . ')[\?\+\*]?)*\s*\)';
my $ENUM_TYPE = '\(\s*' . $TOKN_NAME . '(?:\s*\|\s*' . $TOKN_NAME . ')*\s*\)';
my $ENUM_TYPE_REF = 'Enum:';
my $JAVA_TYPE_REF = 'Java:';
my $ATTR_TYPE = 'CDATA|ID|IDREFS?|ENTITY|ENTITIES|NMTOKENS?|'
                . $JAVA_TYPE_REF . $NAME . '|' . $ENUM_TYPE_REF . $NAME
                . '|' . $ENUM_TYPE;
my $ATTR_VALUE = '\#REQUIRED|\#IMPLIED|(?:\#FIXED\s+)?'
                 . '(?:\".*?\"|\\\'.*?\\\')';
my $PARSE_CONTENT_ALT = '[\(\|]\s*(' . $ELEM_NAME . ')([\+]?)\s*';
my $PARSE_CONTENT_SEQ = '[\(\,]\s*(?:(' . $ELEM_NAME . ')|(' . $CONTENT_ALT
                        . '))([\?\*\+]?)\s*';
my $PARSE_ENUM_TYPE = '\(\s*(.*?)\s*\)';
my $SPLIT_ENUM_TYPE = '\s*\|\s*';
my $PARSE_ATTR_VALUE = '(\#REQUIRED|\#IMPLIED|\#FIXED|)\s*'
                       . '(?:\"(.*?)\"|\\\'(.*?)\\\')?';

my ($parse_content_alt, $parse_content_seq);

sub parse
{
    my (
        $dtdType,   # dtdType should be one of: cCPS1, cCPS2, cCTE, cWS, cCBD
        $file
    ) = @_;

    my %dtd;
    my $comments_for;
    my %comments;
    my $attlist_for;

    my @TYPES;

    my $parser;
    if ($dtdType eq 'cCPS1' || $dtdType eq 'cCPS2') {
        if ($dtdType eq 'cCPS1') {
            $parser = "net.ifao.application.communication.profile.DataConverterV1";
        } else {
            $parser = "net.ifao.application.communication.profile.DataConverterV2";
        }
        push(@TYPES, { name=>'String',             type=>'Java', parser=>undef,   xmlType=>"xs:string", value=>'net.ifao.application.communication.profile.ValidatableText'     });
        push(@TYPES, { name=>'Text',               type=>'Java', parser=>undef,   xmlType=>"xs:string", value=>'net.ifao.application.communication.profile.ValidatableText'     });
        push(@TYPES, { name=>'Name',               type=>'Java', parser=>$parser, xmlType=>"xs:string", value=>'net.ifao.application.communication.profile.ValidatableText'     });
        push(@TYPES, { name=>'Phone',              type=>'Java', parser=>$parser, xmlType=>"xs:string", value=>'net.ifao.application.communication.profile.Phone'               });
        push(@TYPES, { name=>'EMail',              type=>'Java', parser=>$parser, xmlType=>"xs:string", value=>'net.ifao.application.communication.profile.EMail'               });
        push(@TYPES, { name=>'Timestamp',          type=>'Java', parser=>$parser, xmlType=>"xs:string", value=>'net.ifao.application.communication.profile.Timestamp'           });
        push(@TYPES, { name=>'Contact',            type=>'Java', parser=>$parser, xmlType=>"xs:string", value=>'net.ifao.application.communication.profile.ValidatableText'     });
        push(@TYPES, { name=>'ZipCode',            type=>'Java', parser=>$parser, xmlType=>"xs:string", value=>'net.ifao.application.communication.profile.ZipCode'             });
        push(@TYPES, { name=>'StateCode',          type=>'Java', parser=>$parser, xmlType=>"xs:string", value=>'net.ifao.application.communication.profile.StateCode'           });
        push(@TYPES, { name=>'CountryCode',        type=>'Java', parser=>$parser, xmlType=>"xs:string", value=>'net.ifao.application.communication.profile.CountryCode'         });
        push(@TYPES, { name=>'LanguageCode',       type=>'Java', parser=>undef,   xmlType=>"xs:string", value=>'String'                                                         });
        push(@TYPES, { name=>'Language',           type=>'Java', parser=>$parser, xmlType=>"xs:string", value=>'net.ifao.application.communication.profile.Language'            });
        push(@TYPES, { name=>'CurrencyCode',       type=>'Java', parser=>$parser, xmlType=>"xs:string", value=>'net.ifao.application.communication.profile.CurrencyCode'        });
        push(@TYPES, { name=>'AirlineCode',        type=>'Java', parser=>$parser, xmlType=>"xs:string", value=>'net.ifao.application.communication.profile.AirlineCode'         });
        push(@TYPES, { name=>'CarRentalVendorCode',type=>'Java', parser=>$parser, xmlType=>"xs:string", value=>'net.ifao.application.communication.profile.CarRentalVendorCode' });
        push(@TYPES, { name=>'IdentityCardType',   type=>'Java', parser=>$parser, xmlType=>"xs:string", value=>'net.ifao.application.communication.profile.IdentityCardType'    });
        push(@TYPES, { name=>'DynaWebRetriever',   type=>'Java', parser=>$parser, xmlType=>"xs:string", value=>'net.ifao.application.communication.profile.DynaWebRetriever'    });
        push(@TYPES, { name=>'Day',                type=>'Java', parser=>$parser, xmlType=>"xs:string", value=>'net.ifao.application.communication.profile.Day'                 });
        push(@TYPES, { name=>'Month',              type=>'Java', parser=>$parser, xmlType=>"xs:string", value=>'net.ifao.application.communication.profile.Month'               });
        push(@TYPES, { name=>'Year',               type=>'Java', parser=>$parser, xmlType=>"xs:string", value=>'net.ifao.application.communication.profile.Year'                });
        push(@TYPES, { name=>'Symbol',             type=>'Java', parser=>$parser, xmlType=>"xs:string", value=>'net.ifao.application.communication.profile.Symbol'              });
        push(@TYPES, { name=>'Obfuscated',         type=>'Java', parser=>$parser, xmlType=>"xs:string", value=>'net.ifao.application.communication.profile.Obfuscated'          });
    } elsif ($dtdType eq 'cCTE' || $dtdType eq 'cWS' || $dtdType eq 'cCBD') {
        if ($dtdType eq 'cCTE') {
            $parser = "net.ifao.companion.ccbd.template.jaxb.DataConverter";
        } else {
            $parser = "net.ifao.companion.ccbd.template.jaxb.DataConverter";
        }
        push(@TYPES, { name=>'String',             type=>'Java', parser=>undef,   xmlType=>"xs:string", value=>'String'                                                         });
        push(@TYPES, { name=>'Text',               type=>'Java', parser=>undef,   xmlType=>"xs:string", value=>'String'                                                         });
        push(@TYPES, { name=>'ZipCode',            type=>'Java', parser=>undef,   xmlType=>"xs:string", value=>'String'                                                         });
        push(@TYPES, { name=>'IataLocationCode',   type=>'Java', parser=>$parser, xmlType=>"xs:string", value=>'String'                                                         });
        push(@TYPES, { name=>'IataAirlineCode',    type=>'Java', parser=>$parser, xmlType=>"xs:string", value=>'String'                                                         });
        push(@TYPES, { name=>'CCCompanyCode',      type=>'Java', parser=>$parser, xmlType=>"xs:string", value=>'String'                                                         });
        push(@TYPES, { name=>'DateAndTime',        type=>'Java', parser=>$parser, xmlType=>"xs:string", value=>'java.util.Date'                                                 });
        push(@TYPES, { name=>'IxultBoolean',       type=>'Comp', parser=>$parser, xmlType=>"xs:string", value=>'net.ifao.application.communication.ixult.jaxb.IxultBoolean'     });
        push(@TYPES, { name=>'IxultInteger',       type=>'Comp', parser=>$parser, xmlType=>"xs:string", value=>'net.ifao.application.communication.ixult.jaxb.IxultInteger'     });
        push(@TYPES, { name=>'IxultLong',          type=>'Comp', parser=>$parser, xmlType=>"xs:string", value=>'net.ifao.application.communication.ixult.jaxb.IxultLong'        });
        push(@TYPES, { name=>'IxultFloat',         type=>'Comp', parser=>$parser, xmlType=>"xs:string", value=>'net.ifao.application.communication.ixult.jaxb.IxultFloat'       });
        push(@TYPES, { name=>'IxultDate',          type=>'Comp', parser=>$parser, xmlType=>"xs:string", value=>'net.ifao.application.communication.ixult.jaxb.IxultDate'        });
        push(@TYPES, { name=>'IxultTime',          type=>'Comp', parser=>$parser, xmlType=>"xs:string", value=>'net.ifao.application.communication.ixult.jaxb.IxultTime'        });
        push(@TYPES, { name=>'Tristate',           type=>'Java', parser=>$parser, xmlType=>"xs:string", value=>'net.ifao.companion.ccbd.template.jaxb.Tristate'          });
#       push(@TYPES, { name=>'CibHotelChainCode',  type=>'Java', parser=>$parser, xmlType=>"xs:string", value=>'String'                                                         });
    }

    push(@TYPES, { name=>'Boolean',            type=>'Java', parser=>$parser, xmlType=>"xs:string",  value=>'java.lang.Boolean'                                             });
    push(@TYPES, { name=>'Byte',               type=>'Java', parser=>$parser, xmlType=>"xs:integer", value=>'byte'                                                          });
    push(@TYPES, { name=>'Short',              type=>'Java', parser=>$parser, xmlType=>"xs:integer", value=>'short'                                                         });
    push(@TYPES, { name=>'Integer',            type=>'Java', parser=>$parser, xmlType=>"xs:integer", value=>'int'                                                           });
    push(@TYPES, { name=>'Long',               type=>'Java', parser=>$parser, xmlType=>"xs:integer",value=>'long'                                                           });
    push(@TYPES, { name=>'Float',              type=>'Java', parser=>$parser, xmlType=>"xs:decimal", value=>'float'                                                         });
    push(@TYPES, { name=>'Double',             type=>'Java', parser=>$parser, xmlType=>"xs:decimal", value=>'double'                                                        });
    push(@TYPES, { name=>'Character',          type=>'Java', parser=>$parser, xmlType=>"xs:string",  value=>'char'                                                          });
    push(@TYPES, { name=>'Date',               type=>'Java', parser=>$parser, xmlType=>"xs:string", value=>'java.util.Date'                                                 });
    push(@TYPES, { name=>'Time',               type=>'Java', parser=>$parser, xmlType=>"xs:string",  value=>'java.util.Date'                                                });
    push(@TYPES, { name=>'DateTime',           type=>'Java', parser=>$parser, xmlType=>"xs:string",  value=>'java.util.Date'                                                });
    push(@TYPES, { name=>'Duration',           type=>'Java', parser=>$parser, xmlType=>"xs:string",  value=>'java.util.Date'                                                });
    push(@TYPES, { name=>'EncryptedNumber',    type=>'Java', parser=>$parser, xmlType=>"xs:string",  value=>'java.lang.String'                                              });
    push(@TYPES, { name=>'Version',            type=>'Java', parser=>$parser, xmlType=>"xs:string",  value=>'net.ifao.util.Version'                                         });
#   push(@TYPES, { name=>'IfaoDate',           type=>'Java', parser=>$parser, xmlType=>"xs:date",    value=>'net.ifao.util.Date'                                            });
#   push(@TYPES, { name=>'IfaoTime',           type=>'Java', parser=>$parser, xmlType=>"xs:date",    value=>'net.ifao.util.Time'                                            });

    my %TYPE_BY_NAME = ( map { $_->{name} => $_ } @TYPES );

    my %baseTypes=(
        Name=>{},
        Date=>{},
        Obfuscated=>{},
        String=>{}
    );

    sub getBaseTypes
    {
        return %baseTypes;
    }

    while (<$file>) {
        # Trim leading and trailing spaces
        s/^\s*(.*?)\s*$/$1/;

        # Expand parametric entities defined so far
        1 while s{\%($ETTY_NAME)\;}
                 {exists $dtd{entity_by_name}{$1}
                  ? $dtd{entity_by_name}{$1}{value}
                  : "?$1?"}oe;
        if (/^<!DOCTYPE\s+($ELEM_NAME)\s+\[$/o) {
            # Rememeber the root element
            $dtd{elements}[0]{name} = $1;
            $dtd{element_by_name}{$1} = $dtd{elements}[0];
        } elsif (/^<!ENTITY\s+\%\s+($ETTY_NAME)\s+(?:\"(.*)\"|\'(.*)\')\s*>$/o) {
            my $entity_name = $1;
            my $entity_value = $2 || $3;
            die "Entity %" . $entity_name . "; has been already defined!"
                if exists $dtd{entity_by_name}{$entity_name};

            if (exists $TYPE_BY_NAME{$entity_name}
                && ($entity_value eq 'CDATA' || $entity_value eq '#PCDATA')) {
                # Pre-defined type
                my $entity = { name  => $entity_name,
                               value => $JAVA_TYPE_REF . $entity_name };
                push(@{$dtd{entities}}, $entity);
                $dtd{entity_by_name}{$entity_name} = $entity;

                my $type = $TYPE_BY_NAME{$entity_name};
                push(@{$dtd{types}}, $type);
                $dtd{type_by_name}{$entity_name} = $type;
            } elsif ($entity_value =~ /^$ENUM_TYPE$/o) {
                # Enumerated type
                my $entity = { name  => $entity_name,
                               value => $ENUM_TYPE_REF . $entity_name };
                push(@{$dtd{entities}}, $entity);
                $dtd{entity_by_name}{$entity_name} = $entity;

                if ($comments_for eq '?') {
                    $comments_for = $entity_name;
                } elsif ($comments_for ne $entity_name) {
                    undef $comments_for;
                    undef %comments;
                }
                my $type = { name => $entity_name,
                             info => $comments{''},
                             type => 'Enum'
                           };
                push(@{$dtd{types}}, $type);
                $dtd{type_by_name}{$entity_name} = $type;

                # Values
                my ($values) = ($entity_value =~ /^$PARSE_ENUM_TYPE$/o);
                foreach my $value (split(/$SPLIT_ENUM_TYPE/o, $values)) {
                    push(@{$type->{value}},
                         { name => $value,
                           info => $comments{$value}
                         });
                }
            } else {
                my $entity = { name  => $entity_name,
                               value => $entity_value };
                push(@{$dtd{entities}}, $entity);
                $dtd{entity_by_name}{$entity_name} = $entity;
            }
        } elsif (/^<!--\s+([^\s\-].*?)(\s+-->)?$/) {
            # Begin element comment
            $comments_for = ($2 ? '?' : '!');
            %comments = ('' => $1);
        } elsif ($comments_for eq '!') {
            if (/^-->$/) {
                # End element comment
                $comments_for = '?';
            } elsif (/^(.+?)\s+-\s+(.+)$/) {
                # Remember attribute or child element comment
                $comments{$1} = $2;
            }
        } elsif (/^<!ELEMENT\s+($ELEM_NAME)\s+(.+?)\s*>$/o) {
            my $element_name = $1;
            my $content_model = $2;

            my $element = $dtd{element_by_name}{$element_name};

            # Add the element
            if (!defined $element) {
                $element = { name => $element_name };
                push(@{$dtd{elements}}, $element);
                $dtd{element_by_name}{$element_name} = $element;
            }

            # Check if comments exist for this element
            if ($comments_for eq '?') {
                $comments_for = $element_name;
            } elsif ($comments_for ne $element_name) {
                undef $comments_for;
                undef %comments;
            }

            # Add element info, if available
            $element->{info} = $comments{''};

            # Add element options, if available
            while (my ($option_name, $option_value) = each (%comments)) {
                if ($option_name =~ /^\@(\S+)$/) {
                    $element->{options}{$1} = $option_value;
                }
            }

            # Add content model
            if ($content_model =~ /^$CONTENT_EMPTY$/o) {
                # print "EMPTY NAME: $element_name, MODEL: $content_model\n";
                # Empty content
                $element->{content} = [];
            } elsif ($content_model =~ /^$CONTENT_PCDATA$/o) {
                # print "PCDATA NAME: $element_name, MODEL: $content_model\n";
                # Text content
                my $type_name = 'Text';
                my $type = $dtd{type_by_name}{$type_name};
                if (!defined $type) {
                    $type = $TYPE_BY_NAME{$type_name};
                    push @{$dtd{types}}, $type;
                    $dtd{type_by_name}{$type_name} = $type;
                }

                $element->{content} = [
                    { info => undef,
                      type => $type }
                ];
            } elsif ($content_model =~ /^$\\(\s*$JAVA_TYPE_REF($NAME)\s*\)$/o) {
                # Typed text content ??? CHECK ME: Seems like this is used only in ixult
                my $type_name = $comments{'PCDATA'} ? $comments{'PCDATA'} : $1;
                #print "JAVA NAME: $element_name, MODEL: $content_model, TYPE_NAME: $type_name \n";
                my $type = $dtd{type_by_name}{$type_name};
                if (!defined $type) {
                    $type = $TYPE_BY_NAME{$type_name};
                    push @{$dtd{types}}, $type;
                    $dtd{type_by_name}{$type_name} = $type;
                }

                $element->{content} = [
                    { info => undef,
                      type => $type }
                ];
            } elsif ($content_model =~ /^$CONTENT_SEQ$/o) {
                #print "SEQ NAME: $element_name, MODEL: $content_model\n";
                # Sequential content
                $element->{content} = &$parse_content_seq($content_model,
                                                          \%comments);
            } else {
#            } elsif ($content_model =~ /^$CONTENT_ALT$/o) {
                #print "ALT  NAME: $element_name, MODEL: $content_model\n";
                # Alternative content
                $element->{content} = &$parse_content_alt($content_model,
                                                          \%comments);
            }
        } elsif ($attlist_for eq '' && /^<!ATTLIST\s+($ELEM_NAME)$/o) {
            # Begin attribute(s) declaration
            my $element_name = $1;
            $attlist_for = $element_name;

            # Check if comments exist for this element
            if ($comments_for eq '?') {
                $comments_for = $element_name;
            } elsif ($comments_for ne $element_name) {
                undef $comments_for;
                undef %comments;
            }
        } elsif ($attlist_for ne '') {
            my $attlist_end = s/>$//;
            if (/^($ATTR_NAME)\s+($ATTR_TYPE)\s+($ATTR_VALUE)$/o) {
                # Remember attribute declaration
                my $attr_name = $1;
                my $attr_type = $2;
                $3 =~ /^$PARSE_ATTR_VALUE$/;
                my $attr_value = $1;
                my $attr_value_default = (defined $2 ? $2 : $3);
                push(@{$dtd{element_by_name}{$attlist_for}{attributes}},
                     { name    => $attr_name,
                       info    => $comments{$attr_name},
                       type    => $attr_type =~ /^($JAVA_TYPE_REF|$ENUM_TYPE_REF)($NAME)$/
                                  ? $dtd{type_by_name}{$2} : $attr_type,
                       value   => $attr_value,
                       default => $attr_value_default
                     });

                     if ($dtdType eq 'cCPS1' || $dtdType eq 'cCPS2') {
                         if ($dtd{type_by_name}{$2}) {
                             (my $not_used, my $typeName) = split(':', $attr_type);

                             if (exists $baseTypes{$typeName}) {
                                 my $cn = $attr_name.$typeName;
                                 my $tv = $TYPE_BY_NAME{$typeName}{value};

                                 push(@{$dtd{types}}, {
                                     name    => $cn,
                                     type    => 'Java',
                                     xmlType => "xs:string",
                                     parser  => $parser,
                                     value   => $tv,
                                     parent  => $typeName,
                                     child   => $attr_name,
                                     context => $attlist_for
                                     });
                             }
                         }
                    }
            }
            if ($attlist_end) {
                # End attribute(s) declaration
                undef $attlist_for;
            }
        }
    }

    return %dtd;
}

$parse_content_alt = sub($$) {
    my ($content, $infos) = @_;
    my @result = ();

    while ($content =~ /$PARSE_CONTENT_ALT/og) {
        my ($element_name, $occurs) = ($1, $2);

         if ($occurs eq '') {
            # Simple alternative item
            push(@result,
                 { name    => $element_name,
                   info    => $infos->{$element_name},
                   occurs  => '|'
                 });
        } else {
            # Complex alternative item
            push(@result,
                 { content => &$parse_content_seq($element_name . $occurs,
                                                  $infos),
                   occurs  => '|'
                 });
        }
    }

    return \@result;
};

$parse_content_seq = sub ($$) {
    my ($content, $infos) = @_;
    my @result = ();

    while ($content =~ /$PARSE_CONTENT_SEQ/og) {
        my ($element_name, $alt_content, $occurs) = ($1, $2, $3);

        if ($alt_content eq '') {
            # Simple sequence item
            push(@result,
                 { name   => $element_name,
                   info   => $infos->{$element_name},
                   occurs => ($occurs || '!')
                 });
        } else {
            # Complex alternative item
            push(@result,
                 { content => &$parse_content_alt($alt_content, $infos),
                   occurs  => ($occurs || '!')
                 });
        }
    }

    return \@result;
};
