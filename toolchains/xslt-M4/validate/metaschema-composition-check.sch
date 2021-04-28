<?xml version="1.0" encoding="UTF-8"?>
<sch:schema xmlns:sch="http://purl.oclc.org/dsdl/schematron" queryBinding="xslt2"
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:m="http://csrc.nist.gov/ns/oscal/metaschema/1.0"
    xmlns:nm="http://csrc.nist.gov/ns/metaschema"
    xmlns:sqf="http://www.schematron-quickfix.com/validator/process"
    xmlns:oscal="http://csrc.nist.gov/ns/oscal/1.0">

<!-- Extra-XSD validation for NIST Metaschema format 

    This is ISO Schematron with XSLT extensions, requiring 'allow-foreign-namespace' to run.

       -->

    <sch:ns uri="http://csrc.nist.gov/ns/oscal/metaschema/1.0" prefix="m"/>
    <sch:ns uri="http://csrc.nist.gov/ns/metaschema" prefix="nm"/>
    
    <xsl:import href="metaschema-validation-support.xsl"/>
    
    <xsl:import href="oscal-datatypes-check.xsl"/>
    
    
    <!--<xsl:import href="oscal-datatypes-check.xsl"/>-->
    
    <xsl:variable name="composed-metaschema" select="nm:compose-metaschema(/)"/>
 
    <!--<sch:let name="metaschema-is-abstract" value="/m:METASCHEMA/@abstract='yes'"/>-->
    
    <sch:pattern id="top-level-and-schema-docs">
        <sch:rule context="/m:METASCHEMA">
            <sch:assert test="exists($composed-metaschema)">Can't find composition...</sch:assert>
            <sch:assert test="exists(m:schema-version)" role="warning">Metaschema schema version must be set for any top-level metaschema</sch:assert>
            <sch:assert test="exists(@abstract='yes' or $composed-metaschema/m:define-assembly/m:root-name)">Unless marked as @abstract='yes', a metaschema (or an imported metaschema) should have at least one assembly with a root-name.</sch:assert>
        </sch:rule>
        <sch:rule context="/m:METASCHEMA/m:import">
            <sch:report role="warning" test="document-uri(/) = resolve-uri(@href,document-uri(/))">Schema can't import itself</sch:report>
            <sch:assert test="exists(document(@href)/m:METASCHEMA)">Can't find a metaschema at <sch:value-of select="@href"/></sch:assert>
        </sch:rule>
    </sch:pattern>
    
    
    
    <sch:pattern id="detect-duplicates-and-name-clashes">
        
        <sch:rule context="m:assembly | m:field | m:flag">
            <!--<sch:report test="true()">ID: <xsl:value-of select="nm:metaschema-module-node-identifier(.)"/></sch:report>
            <sch:report test="true()">
                <xsl:for-each select="$composed-metaschema//m:define-assembly | $composed-metaschema//m:define-field | $composed-metaschema//m:define-flag
                    | $composed-metaschema//m:flag | $composed-metaschema//m:field | $composed-metaschema//m:assembly">
                    <xsl:if test="position() > 1">, </xsl:if>
                    <xsl:value-of select="nm:composed-node-id(.)"/>
                </xsl:for-each>
            </sch:report>
            <sch:report test="true()">As composed: '<xsl:value-of select="key('composed-node-by-identifier',nm:metaschema-module-node-identifier(.),$composed-metaschema)/serialize(.)" separator=", "/>'</sch:report>-->
            

            <xsl:variable name="maybe-composed" as="element()*" select="key('composed-node-by-identifier',nm:metaschema-module-node-identifier(.),$composed-metaschema)"/>
            
            <xsl:variable name="as-composed" as="element()?" select="$maybe-composed[count($maybe-composed) eq 1]"/>         
            <xsl:variable name="is-multiple"  select="count($maybe-composed) gt 1"/>
            
            <sch:let name="my-xml-name"  value="$as-composed/@in-xml-name"/>
            <sch:let name="my-json-name" value="$as-composed/@in-json-name"/>
            <sch:let name="named-like-me-in-xml" value="$as-composed/ancestor::m:model[1]/(*|m:choice/*)[@in-xml-name=$my-xml-name]"/>
            
            <sch:let name="named-like-me-in-json" value="$as-composed/ancestor::m:model[1]/(*|m:choice/*)[@in-json-name=$my-json-name]"/>
            
            <sch:assert test="not($is-multiple)" >Duplicate found for <sch:name/> reference to <sch:value-of select="@ref"/> in <xsl:value-of select="$maybe-composed/(ancestor-or-self::m:define-assembly|ancestor-or-self::m:define-field|ancestor::m:define-flag)/@_base-uri" separator=", "/>. Is this due to a duplicated METASCHEMA/short-name in a module?</sch:assert>
<!--            <sch:report test="$is-multiple">Matching <xsl:value-of select="$maybe-composed/serialize(.)" separator=", "/></sch:report>
-->            
            <sch:assert test="empty($as-composed) or $is-multiple or count($named-like-me-in-json) = 1">Name clash among siblings (properties of the same object) with JSON name '<sch:value-of select="$my-json-name"/>'.</sch:assert>
            <sch:assert test="empty($as-composed) or $is-multiple or count($named-like-me-in-xml) = 1">Name clash among siblings with XML name '<sch:value-of select="$my-xml-name"/>'.</sch:assert>
        </sch:rule>
        
        <sch:rule context="m:define-flag | m:define-field | m:define-assembly">
<!--            <sch:report test="true()">ID: <xsl:value-of select="nm:metaschema-module-node-identifier(.)"/></sch:report>
            <sch:report test="true()">
                <xsl:for-each select="$composed-metaschema//m:define-assembly | $composed-metaschema//m:define-field | $composed-metaschema//m:define-flag
                    | $composed-metaschema//m:flag | $composed-metaschema//m:field | $composed-metaschema//m:assembly">
                    <xsl:if test="position() > 1">, </xsl:if>
                    <xsl:value-of select="nm:composed-node-id(.)"/>
                </xsl:for-each>
            </sch:report>
            <sch:report test="true()">As composed: '<xsl:value-of select="key('composed-node-by-identifier',nm:metaschema-module-node-identifier(.),$composed-metaschema)/serialize(.)" separator=", "/>'</sch:report>
-->
            <sch:let name="def-id" value="nm:metaschema-module-node-identifier(.)"/>
            <!--<sch:report test="true()">Seeing <sch:value-of select="$def-id"/></sch:report>-->
            <xsl:variable name="maybe-composed" as="element()*" select="key('composed-node-by-identifier',nm:metaschema-module-node-identifier(.),$composed-metaschema)"/>
            
            <xsl:variable name="as-composed" as="element()?" select="$maybe-composed[count($maybe-composed) eq 1]"/>
            <xsl:variable name="is-multiple"  select="count($maybe-composed) gt 1"/>
            
            <sch:assert test="not($is-multiple)">Duplicate found for <sch:name/> reference to <sch:value-of select="@ref"/> in <xsl:value-of select="$maybe-composed/(ancestor-or-self::m:define-assembly|ancestor-or-self::m:define-field|ancestor::m:define-flag)/@_base-uri" separator=", "/>. Is this due to a duplicated METASCHEMA/short-name in a module?</sch:assert>
            
        </sch:rule>
    </sch:pattern>
    
    <sch:pattern id="detect-shadowed-definitions">
        <sch:rule context="/m:METASCHEMA/m:define-assembly | /m:METASCHEMA/m:define-field | /m:METASCHEMA/m:define-flag">
<!--            <sch:report test="true()">ID: <xsl:value-of select="nm:metaschema-module-node-identifier(.)"/></sch:report>
            <sch:report test="true()">
                <xsl:for-each select="$composed-metaschema//m:define-assembly | $composed-metaschema//m:define-field | $composed-metaschema//m:define-flag
                    | $composed-metaschema//m:flag | $composed-metaschema//m:field | $composed-metaschema//m:assembly">
                    <xsl:if test="position() > 1">, </xsl:if>
                    <xsl:value-of select="nm:composed-node-id(.)"/>
                </xsl:for-each>
            </sch:report>
            <sch:report test="true()">As composed: '<xsl:value-of select="key('composed-node-by-identifier',nm:metaschema-module-node-identifier(.),$composed-metaschema)/serialize(.)" separator=", "/>'</sch:report>
-->            
            <xsl:variable name="as-composed" as="element()*" select="key('composed-node-by-identifier',nm:metaschema-module-node-identifier(.),$composed-metaschema)"/>
            <!-- filter out current node from defs. This allows a non-match to pass the following assertion, which can happen if the target definition was found to be unused. -->
            <sch:let name="defs" value="key('top-level-definition-by-name',nm:metaschema-definition-identifier(.),$composed-metaschema) except $as-composed"/>
            <sch:assert test="count($defs)=0">Definition shadows by another definition in this (composed) metaschema: see <sch:name/> <xsl:value-of select="$defs/concat(@module,':',@name)" separator=", "/> (<xsl:value-of select="$defs/@_base-uri" separator=", "/>)</sch:assert>
        </sch:rule>
    </sch:pattern>

    <sch:pattern id="group-as">
        <sch:rule context="m:assembly | m:field | m:model/m:define-assembly | m:model/m:define-field">
            <xsl:variable name="as-composed" as="element()*" select="key('composed-node-by-identifier',nm:metaschema-module-node-identifier(.),$composed-metaschema)"/>

            <sch:assert test="not(exists($as-composed)) or number($as-composed/@max-occurs)=1 or exists($as-composed/m:group-as/@name)">Unless @max-occurs is 1, a group-as name must be given within an instance or a local definition.</sch:assert>
        </sch:rule>
    </sch:pattern>


    <sch:pattern id="flags_and_fields_and_datatypes">
        
        <!-- flag references and inline definitions -->
        <sch:rule context="m:flag | m:define-field/m:define-flag | m:define-assembly/m:define-flag">
            <sch:assert
                test="not((@name | @ref) = ../m:json-value-key/@flag-name) or @required = 'yes'">A flag declared as a value key must be required (@required='yes')</sch:assert>
            <sch:assert
                test="not((@name | @ref) = ../m:json-key/@flag-name) or @required = 'yes'">A flag declared as a key must be required (@required='yes')</sch:assert>
        </sch:rule>
        
        <!--field references and inline definitions -->
        <sch:rule context="m:field | m:model//m:define-field">
            <!-- constraints on markup-multiline **XXX** TEST ME -->
            <xsl:variable name="as-composed" as="element()*" select="key('composed-node-by-identifier',nm:metaschema-module-node-identifier(.),$composed-metaschema)"/>
            <sch:assert test="empty($as-composed) or not($as-composed/@in-xml='UNWRAPPED') or not($as-composed/@as-type='markup-multiline') or not(preceding-sibling::*[$as-composed/@in-xml='UNWRAPPED']/@as-type='markup-multiline')">Only one field may be marked as 'markup-multiline' (without xml wrapping) within a model.</sch:assert>
            <sch:report test="($as-composed/@in-xml='UNWRAPPED') and (@max-occurs!='1')">An 'unwrapped' field must have a max occurrence of 1</sch:report>
            <sch:assert test="$as-composed/@as-type='markup-multiline' or not($as-composed/@in-xml='UNWRAPPED')">Only 'markup-multiline' fields may be unwrapped in XML.</sch:assert>

</sch:rule>
        
        <sch:rule context="m:define-field">
            <!-- use @subject to refine the reporting? -->
            <sch:assert test="empty(m:flag|m:define-flag) or not(@as-type='markup-multiline' and @in-xml='UNWRAPPED')">Multiline markup fields must have no flags, unless always used with a wrapper - put your flags on an assembly with an unwrapped multiline field.</sch:assert>
        </sch:rule>

        <sch:rule context="m:json-key">
            <sch:let name="json-key-flag-name" value="@flag-name"/>
            <sch:let name="json-key-flag" value="../m:flag[@ref=$json-key-flag-name] |../m:define-flag[@name=$json-key-flag-name]"/>
            <sch:assert test="exists($json-key-flag)">JSON key indicates no flag on this <sch:value-of select="substring-after(local-name(..),'define-')"/> <xsl:if test="exists(../m:flag | ../m:define-flag)">Should be (one of) <xsl:value-of select="../m:flag/@ref | ../m:define-flag/@name" separator=", "/></xsl:if></sch:assert>
        </sch:rule>
        
        <sch:rule context="m:json-value-key">
            <sch:assert test="empty(@flag-name) or (@flag-name != ../(m:flag/@ref | m:define-flag/@name) )"><sch:name/> as flag/<sch:value-of select="@flag-name"/> will be inoperative as the value will be given the field key -- no other flags are given <xsl:value-of select="../(m:flag|m:define-flag)/@ref" separator=", "/></sch:assert>
            <sch:report test="exists(@flag-name) and matches(.,'\S')">JSON value key may be set to a value or a flag's value, but not both.</sch:report>
            <sch:assert test="empty(@flag-name) or @flag-name = (../m:flag/@ref|../m:define-flag/@name)">flag '<sch:value-of select="@flag-name"/>' not found for JSON value key</sch:assert>
        </sch:rule>
        
        <sch:rule context="m:allowed-values/m:enum">
            <sch:assert test="not(@value = preceding-sibling::*/@value)">Allowed value '<sch:value-of select="@value"/>' may only be specified once for flag '<sch:value-of select="../../@name"/>'.</sch:assert>
            <sch:assert test="m:datatype-validate(@value,../../@as-type)">Value '<sch:value-of select="@value"/>' is not a valid token of type <sch:value-of select="../../@as-type"/></sch:assert>
        </sch:rule>
        
        <sch:rule context="m:index | m:is-unique">
            <sch:assert test="count(key('index-by-name',@name,$composed-metaschema))=1">Only one index or uniqueness assertion may be named '<sch:value-of select="@name"/>'</sch:assert>
        </sch:rule>
        
        <sch:rule context="m:index-has-key">
            <sch:assert test="count(key('index-by-name',@name,$composed-metaschema)/self::m:index)=1">No '<sch:value-of select="@name"/>' index is defined.</sch:assert>
        </sch:rule>
        
        <sch:rule context="m:key-field">
            <sch:report test="@target = preceding-sibling::*/@target">Index key field target '<sch:value-of select="@target"/>' is already declared.</sch:report>
        </sch:rule>
    </sch:pattern>
    
    <xsl:key name="index-by-name" match="m:index | m:is-unique" use="@name"/>
    
    <sch:pattern id="schema-docs">
        <sch:rule context="m:define-assembly | m:define-field | m:define-flag">
            <sch:assert role="warning" test="exists(m:formal-name)">Formal name missing from <sch:name/></sch:assert>
            <sch:assert role="warning" test="exists(m:description)">Short description missing from <sch:name/></sch:assert>
        </sch:rule>
        
        <sch:rule context="m:p | m:li | m:pre">
            <sch:assert test="matches(.,'\S')">Empty <name/> (is likely to distort rendition)</sch:assert>
            <sch:report role="warning" test="not(matches(.,'\w'))">Not much here is there</sch:report>
        </sch:rule>
    </sch:pattern>
    
    
    <!-- 0#0|0#0|0#0|0#0|0#0|0#0|0#0|0#0|0#0|0#0|0#0|0#0|0#0|0#0|0#0|0#0|0#0|0#0|0#0|0#0|0#0|0#0|0#0|0#0|-->
    
    <!--<xsl:function name="nm:has-a-distinct-name" as="xs:boolean">
        <!-\- checks a field or assembly as referenced in a modeled (i.e. references and inline definitions)
             and returns if they have distinct names -\->
    </xsl:function>-->
    
    <xsl:function name="nm:composed-node-id" as="xs:string">
        <xsl:param name="who" as="element()"/>
        <xsl:variable name="top-level-definition" select="$who/ancestor-or-self::m:define-assembly[parent::m:METASCHEMA] |
            $who/ancestor-or-self::m:define-field[parent::m:METASCHEMA] | 
            $who/ancestor-or-self::m:define-flag[parent::m:METASCHEMA]"/>
        <xsl:variable name="module-defined" select="$top-level-definition/@module"/>
        <xsl:value-of
            select="($module-defined,
            $who/ancestor-or-self::*/(@name | @ref),
            name($who), $who/m:use-name) => string-join('#')"/>
    </xsl:function>
    
    <xsl:function name="nm:metaschema-module-node-identifier" as="xs:string">
        <xsl:param name="who" as="element()"/>
        <xsl:value-of
            select="($who/root()/*/m:short-name,
            $who/ancestor-or-self::*/(@name | @ref),
            name($who), $who/m:use-name) => string-join('#')"/>
    </xsl:function>

    <xsl:function name="nm:metaschema-definition-identifier" as="xs:string">
        <xsl:param name="who" as="element()"/>
        <xsl:value-of
            select="(name($who),$who/@name) => string-join('#')"/>
    </xsl:function>
    

    <xsl:key name="top-level-definition-by-name" use="nm:metaschema-definition-identifier(.)"
        match="m:METASCHEMA/m:define-assembly[not(@scope='local')] |
        m:METASCHEMA/m:define-field[not(@scope='local')] |
        m:METASCHEMA/m:define-flag[not(@scope='local')]"/>
    
    <xsl:key name="composed-node-by-identifier"
        match="m:define-assembly | m:define-field | m:define-flag
        | m:flag | m:field | m:assembly" use="nm:composed-node-id(.)"/>
    
    
</sch:schema>