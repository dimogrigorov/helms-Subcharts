#!/usr/bin/perl

use lib($0 =~ /^(.*)[\/\\]/ && $1 || '.');
use Data::Dumper;  ### install using: cpan install Data::Dumper
use strict;

# Replacement for attributes named "class" and "Class"
use constant CLASS_ATTRIBUTE_REPLACEMENT => 'class2';
use constant ATTRIBUTE_PROPERTY_SUFFIX => 'Attr';

use IO::File;
use DTDParser_xsd;

my $dtdType = shift;    # dtdType should be one of: nonProfile, profileV1, profileV2
my $file = shift;

my %dtd = DTDParser_xsd::parse($dtdType, new IO::File($file));
my %baseTypes = DTDParser_xsd::getBaseTypes();

#print Data::Dumper->Dumper(\%dtd);

my($file_name) = ($file =~ /([^\\\/]+)$/);
my $java_package = $dtd{entity_by_name}{JavaPackage}{value};
my $java_prefix = $dtd{entity_by_name}{JavaPrefix}{value};

# new entity of JavaPrefixCamel to create classes like BookreservationMessage
# instead of Bookreservationmessage (if JavaPrefix = "Bookreservation")
# with this you'll get a mixed camelcase classname.

my $java_prefix_camel = $dtd{entity_by_name}{JavaPrefixCamel}{value};

my %class_required;

sub mark_class_required(\%\@$);
sub find_element_by_name(\@$);

# ============================================================
sub xml_escape {
# ============================================================
# Transforms and filters input characters to acceptable XML characters
# (or filters them out completely). There's probably a better
# implementation of this in another module, by now.
# ------------------------------------------------------------
	local $_ = shift;
	return $_ if not defined $_;
    s/&/&amp;/g;
    s/</&lt;/g;
    s/>/&gt;/g;
    s/[\0\ca\cb\cc\cd\ce\cf\cg\ch\ck\cl\cn\co\cp\cq\cr\cs\ct\cu\cv\cw\cx\cy\cz\c[\c\\c]\c^\c_]//g;
    s/'/&apos;/g;
    s/"/&quot;/g;
    return $_;
}

sub mark_class_required(\%\@$)
{
    my ($map, $content, $inherited) = @_;
    if ($content && @$content) {
        if ($$content[0]{type}) {
            # #PCDATA content
        } else {
            # Element content
            foreach my $child (@$content) {
                my $class_required = $inherited || $child->{occurs} eq '|';
                if (defined $child->{content} && @{$child->{content}} > 0) {
                    mark_class_required(%$map, @{$child->{content}}, $class_required);
                } elsif ($child->{name} ne '') {
                    if ($class_required) {
                        $$map{$child->{name}} = 1;
                    }
                }
            }
        }
    }
}

sub find_element_by_name(\@$)
{
    my ($content, $name) = @_;

    if ($content && @$content) {
        if ($$content[0]{type}) {
            # #PCDATA content
        } else {
            # Element content
            foreach my $child (@$content) {
                if (defined $child->{content} && @{$child->{content}} > 0) {
                    my $found = find_element_by_name(@{$child->{content}}, $name);

                    return $found if defined $found;
                } elsif ($child->{name} ne '') {
                    if ($name eq "\u$child->{name}") {
                        return $child;
                    }
                }
            }
        }
    }

    return;
}

sub process_attributes {
    my ($indent, $elem) = @_;

    if (!(defined $elem->{attributes}) || (@{$elem->{attributes}} == 0)) {
        return;
    }
    foreach my $attr (@{$elem->{attributes}}) {
        if ($attr->{info} ne '') {
            print "$indent<!-- \u$attr->{info} -->\n";
        }

        # Name and property name
        my $attribute_name = $attr->{name};
        my $attribute_property = ($attribute_name eq 'class'
                                  || $attribute_name eq 'Class')
                                 ? CLASS_ATTRIBUTE_REPLACEMENT
                                 : find_element_by_name(@{$elem->{content}}, "\u$attribute_name")
                                 ? $attribute_name . ATTRIBUTE_PROPERTY_SUFFIX
                                 : undef;
        my $attribute_required = ($attr->{name} eq '#REQUIRED' ? 'use="required"' : "");

        # Type and conversion
        my $type = $attr->{type};
        my $attribute_convert = undef;
        if (ref $type && $type->{type} eq 'Java') {
            my $typeDecl = findTypeDecl($dtd{types}, $attr->{name}, $elem->{name});
            if (!defined $typeDecl) {
                $attribute_convert= "Java$type->{name}";
            }else {
                $attribute_convert = "Java".createName($typeDecl, %baseTypes);
            }
        } elsif (ref $type && $type->{type} eq 'Enum') {
            $attribute_convert = "$type->{name}";
        } elsif (ref $type && $type->{type} eq 'Comp') {
            $attribute_convert = "Java$type->{name}";
        } elsif (ref $type && $type->{type}) {
            $attribute_convert = "$type->{name}";
        } else {
            $attribute_convert = "xs:string";
        }

        my $attribute_default = "";
        #if (defined $attr->{default} && $type->{name} eq 'Version') {
        if (defined $attr->{default}) {
            $attribute_default = "default=\"$attr->{default}\"";
        }
        print "$indent<xs:attribute name='$attribute_name' type='$attribute_convert' $attribute_required $attribute_default/>\n";
    }
}

sub process_content {
    my ($indent, $content, $conentOccurs, $elem, $choice_prop_name) = @_;
    my $in_choice = 0;
    my $iindent = $indent;
    foreach my $c (@$content) {
        my $element_ref_name = $c->{name};
        my $element_ref_type = $element_ref_name;
        my $element_ref_property = $element_ref_name;
        my $elemType = $dtd{element_by_name}{$c->{name}};
        #print Data::Dumper->Dumper($elemType->{content});

        if ($element_ref_name eq 'Java:String') {
            $element_ref_name = 'xs:string';
        } elsif (
                defined $elemType &&
                defined $elemType->{content} &&
                @{$elemType->{content}} == 1 &&
                defined $elemType->{content}[0] &&
                defined $elemType->{content}[0]{type}) {
            if ($elemType->{content}[0]{type}{type} eq 'Enum') {
                $element_ref_type = $elemType->{content}[0]{type}{name};
            } elsif ($elemType->{content}[0]{type}{type} eq 'Comp') {
                $element_ref_type = "Java" . $elemType->{content}[0]{type}{name};
            }
        }
        my $min_occurs = "";
        my $max_occurs = "";

        if ($c->{type}) {
            # do nothing
            next;
        } elsif ($c->{occurs} eq '|') {
            if (!$in_choice) {
                if ($choice_prop_name eq 'Choice') {
                    my $minOccurs = '0';
                    my $maxOccurs = '1';
                    if ($conentOccurs eq '+') {
                        $minOccurs = '1';
                        $maxOccurs = 'unbounded';
                    } elsif ($conentOccurs eq '*') {
                        $maxOccurs = 'unbounded';
                    }
                    print "$iindent<xs:choice minOccurs='$minOccurs' maxOccurs='$maxOccurs'>\n";
                } else {
                    print "$iindent<xs:choice minOccurs='0' maxOccurs='unbounded'>\n";
                }
                print "$iindent    <xs:annotation><xs:appinfo>\n";
                print "$iindent        <jb:property   name='$choice_prop_name' />\n";
                print "$iindent    </xs:appinfo></xs:annotation>\n";
                $iindent = "$indent    ";
                $in_choice = 1;
            }
        } else {
            if ($in_choice) {
                $iindent = $indent;
                $in_choice = 0;
                print "$iindent</xs:choice>\n";
            }

            if ($c->{occurs} eq '+') {
                $min_occurs = "minOccurs='1'";
                $max_occurs = "maxOccurs='unbounded'";
                $element_ref_property .= 'List';
            } elsif ($c->{occurs} eq '*') {
                $min_occurs = "minOccurs='0'";
                $max_occurs = "maxOccurs='unbounded'";
                $element_ref_property .= 'List';
            } elsif ($c->{occurs} eq '?') {
                $min_occurs = "minOccurs='0'";
                $max_occurs = "maxOccurs='1'";
            } elsif ($c->{occurs} eq '!') {
                $min_occurs = "minOccurs='1'";
                $max_occurs = "maxOccurs='1'";
            } else {
                die "Unknown content model: $c->{name}$c->{occurs}";
            }
        }

        my $elementDef = "";
        if ($class_required{$c->{name}}) {
            $elementDef = "ref='$element_ref_name'";
        } else {
            $elementDef = "name='$element_ref_name' type='$element_ref_type'";
        }

        if ($c->{content}) {
            #print "$iindent<xs:complexType>\n";
            #print "$iindent    <!-- Maybe here I should put Choice -->\n";
            process_content("$iindent    ", $c->{content}, $c->{occurs}, $elem, "Choice");
            #print "$iindent</xs:complexType>\n";
        } elsif ($in_choice) {
            print "$iindent<xs:element $elementDef $min_occurs $max_occurs />\n";
        } else {
            print "$iindent<xs:element $elementDef $min_occurs $max_occurs>\n";
            print "$iindent    <xs:annotation><xs:appinfo>\n";
            print "$iindent        <jb:property name='$element_ref_property' />\n";
            print "$iindent    </xs:appinfo></xs:annotation>\n";
            print "$iindent</xs:element>\n";
        }
    }

    if ($in_choice) {
        $iindent = $indent;
        $in_choice = 0;
        print "$iindent</xs:choice>\n";
    }
}

# Determine elements that must be represented by classes
if (defined $dtd{elements} && @{$dtd{elements}} > 0) {
    foreach my $elem (@{$dtd{elements}}) {
        my $root = 1;
        if ((defined $elem->{content}) && (@{$elem->{content}} > 0)) {
            my $content0 = $elem->{content}[0];
            if ($content0->{type} eq 'Comp' || $content0->{type} eq 'Enum') {
                $root = 0;
            } elsif ($content0->{type} && (!(defined $elem->{attributes}) || (@{$elem->{attributes}} == 0))) {
                $root = 0;
            }
        }

        if ($root                                                   # Is root element
            || ($elem->{attributes} && @{$elem->{attributes}})      # or has attributes
            || !$elem->{content}                                    # or has no content
            || @{$elem->{content}} > 1                              # or has multiple children
            || (@{$elem->{content}} && !$elem->{content}[0]{type})  # or has a single child, which is not #PCDATA
        ) {
            $class_required{$elem->{name}} = 1;
        }

        #if (defined $elem->{content} && @{$elem->{content}} > 0) {
        #    mark_class_required(%class_required, @{$elem->{content}}, undef);
        #}
    }
}

if ($java_package eq '') {
    $java_package = 'jaxb';
}

print <<END;
<xs:schema
    xmlns:xs='http://www.w3.org/2001/XMLSchema'
    xmlns:jb="http://java.sun.com/xml/ns/jaxb"
    attributeFormDefault="unqualified"
    elementFormDefault="unqualified"
    jb:version="2.0">

<!-- Schema automatically generated from $file_name -->

    <xs:annotation>
        <xs:appinfo>
            <jb:globalBindings
                enableFailFastCheck = "1"
                choiceContentProperty = "1"
                typesafeEnumMemberName = "generateName">
            </jb:globalBindings>

            <jb:schemaBindings>
                <jb:package name = "$java_package" />
                <!--
                <jb:nameXmlTransform>
                    <jb:elementName prefix="$java_prefix"/>
                    <jb:typeName prefix="$java_prefix"/>
                </jb:nameXmlTransform>
                -->
            </jb:schemaBindings>
        </xs:appinfo>
    </xs:annotation>
END

if (defined $dtd{types} && @{$dtd{types}} > 0) {
    print "\n";
    print "    <!--            -->\n";
    print "    <!-- Data Types -->\n";
    print "    <!--            -->\n";
    foreach my $type (@{$dtd{types}}) {
        if ($type->{type} eq 'Java' || $type->{type} eq 'Comp') {
            if ($type->{info} ne '') {
                print "    <!-- \u$type->{info} -->\n";
            }
            my $typeName= createName($type, %baseTypes);
            print "    <!-- \u$type->{name} = $type->{xmlType} -->\n";
            print "    <xs:simpleType name='Java$typeName'>\n";
            print "        <xs:annotation><xs:appinfo>\n";
            print "            <jb:javaType name = '$type->{value}' hasNsContext = '0'\n";
            if (defined $type->{parser}) {
                print "                parseMethod = '$type->{parser}.parse$typeName'\n";
                print "                printMethod = '$type->{parser}.format$typeName'\n";
            }
            print "             />\n";
            print "        </xs:appinfo></xs:annotation>\n";
            print "        <xs:restriction base='$type->{xmlType}' />\n";
            print "    </xs:simpleType>\n";
        } elsif ($type->{type} eq 'Enum') {
            print "\n";
            if ($type->{info} ne '') {
                print "    <!-- \u$type->{info} -->\n";
            }
            print "    <xs:simpleType name='$type->{name}'>\n";
            print "        <xs:annotation><xs:appinfo>\n";
            print "            <jb:typesafeEnumClass>\n";
            foreach my $enum (@{$type->{value}}) {
                my $info = xml_escape($enum->{info});
                my $v = $enum->{name};
                my $n = $v;
                if ($n =~ /^[0-9]/) {
                    $n = "_$n";
                    print "                <jb:typesafeEnumMember name='$n' value='$v'><jb:javadoc>$info</jb:javadoc></jb:typesafeEnumMember>\n";
                } else {
                    print "                <jb:typesafeEnumMember value='$v'><jb:javadoc>$info</jb:javadoc></jb:typesafeEnumMember>\n";
                }
            }
            print "            </jb:typesafeEnumClass>\n";
            print "        </xs:appinfo></xs:annotation>\n";
            print "        <xs:restriction base='xs:string'>\n";
            foreach my $enum (@{$type->{value}}) {
            print "            <xs:enumeration value='$enum->{name}' />\n";
            }
            print "        </xs:restriction>\n";
            print "    </xs:simpleType>\n";
        } else {
            die "Unknown type: " . Data::Dumper->Dumper($type);
        }
    }
}

print "\n";

if (defined $dtd{elements} && @{$dtd{elements}} > 0) {
    print "\n";
    print "    <!--          -->\n";
    print "    <!-- Elements -->\n";
    print "    <!--          -->\n";
    my $element_root = "true";
    foreach my $elem (@{$dtd{elements}}) {
        print "\n";
        if ($elem->{info} ne '') {
            print "    <!-- \u$elem->{info} -->\n";
        }
        my $element_name = $elem->{name};
        my $element_type = ($class_required{$elem->{name}} ? 'class' : 'value');
        my $element_class = $class_required{$elem->{name}}
                            && ($elem->{options}{class} || $elem->{name});

        $element_root ||= $elem->{options}{root};

#    <element name="$element_name" type="$element_type"@{[$element_class2 && " class=\"$element_class2\""]}@{[$element_root && " root=\"$element_root\""]}>
        undef $element_root;

#        if ($element_class) {
            if ((defined $elem->{content}) && (@{$elem->{content}} > 0)) {
                my $content0 = $elem->{content}[0];
                if ($content0->{type} eq 'Comp' || $content0->{type} eq 'Enum') {
                    # Do not output a type
                } elsif ($content0->{type} && (!(defined $elem->{attributes}) || (@{$elem->{attributes}} == 0))) {
                    print "    <xs:simpleType name='$element_name'>\n";
                    print "        <xs:restriction base='xs:string' />\n";
                    print "    </xs:simpleType>\n";
                } elsif ($content0->{type}) {
                    if ($class_required{$element_name}) {
                        print "    <xs:element name='$element_name'><xs:complexType>\n";
                    } else {
                        print "    <xs:complexType name='$element_name'>\n";
                    }
                    print "        <xs:annotation><xs:appinfo>\n";
                    #print "            <jb:class name='$java_prefix$element_name' />\n";
                    print "            <jb:property name='Content' />\n";
                    print "        </xs:appinfo></xs:annotation>\n";
                    print "\n";
                    print "        <xs:simpleContent>\n";
                    print "            <xs:extension base='xs:string'>\n";
                    process_content("                ", $elem->{content}, "", $elem, "Content");
                    process_attributes("                ", $elem);
                    print "            </xs:extension>\n";
                    print "        </xs:simpleContent>\n";
                    if ($class_required{$element_name}) {
                        print "    </xs:complexType></xs:element>\n";
                    } else {
                        print "    </xs:complexType>\n";
                    }
                } else {
                    if ($class_required{$element_name}) {
                        print "    <xs:element name='$element_name'><xs:complexType>\n";
                    } else {
                        print "    <xs:complexType name='$element_name'>\n";
                    }
                    print "        <xs:annotation><xs:appinfo>\n";
                    #print "            <jb:class name='$java_prefix$element_name' />\n";
                    print "        </xs:appinfo></xs:annotation>\n";
                    print "\n";
                    print "        <xs:sequence>\n";
                    process_content("            ", $elem->{content}, "", $elem, "Content");
                    print "        </xs:sequence>\n";
                    process_attributes("        ", $elem);
                    if ($class_required{$element_name}) {
                        print "    </xs:complexType></xs:element>\n";
                    } else {
                        print "    </xs:complexType>\n";
                    }
                }
            } else {
                if ($class_required{$element_name}) {
                    print "    <xs:element name='$element_name'><xs:complexType>\n";
                } else {
                    print "    <xs:complexType name='$element_name'>\n";
                }
                print "        <xs:annotation><xs:appinfo>\n";
                #print "            <jb:class name='$java_prefix$element_name' />\n";
                print "        </xs:appinfo></xs:annotation>\n";
                print "\n";
                print "        <!-- This element has no content -->\n";
                process_attributes("        ", $elem);
                    if ($class_required{$element_name}) {
                        print "    </xs:complexType></xs:element>\n";
                    } else {
                        print "    </xs:complexType>\n";
                    }
            }

#        }
    }
}

sub findTypeDecl
{
    my ($declarations, $attribute, $element)=@_;

    for my $declaration (@{$declarations}) {
        return $declaration if $declaration->{context} eq $element && $declaration->{child} eq $attribute;
    }
    return undef;
}

sub createName
{
    my ($typeDecl, $baseTypes, $default)=@_;

    if (exists $baseTypes{$typeDecl->{parent}}) {
        return "$typeDecl->{context}".ucfirst($typeDecl->{child})
    }
    return $typeDecl->{name};
}

print "</xs:schema>\n";
