<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:xs="http://www.w3.org/2001/XMLSchema"
    xmlns:json="http://www.oxygenxml.com/ns/expath/json"
    exclude-result-prefixes="xs json"
    version="2.0">
    <xsl:output name="topic" 
        doctype-public="-//OASIS//DTD DITA Topic//EN"
        doctype-system="topic.dtd"
        indent="yes"/>
    
    <xsl:output name="map" 
        doctype-public="-//OASIS//DTD DITA Map//EN"
        doctype-system="map.dtd"
        indent="yes"/>
    
    
    <!-- Generate DITA content for an OpenAPI spec. -->
    <xsl:template name="main">
        <xsl:variable name="descriptor" select="json-to-xml(unparsed-text('../3.%20openapi/3.%20Convert%20OpenAPI%20to%20DITA/fusion.json'))/*:map"/>
        <xsl:for-each select="json:get($descriptor, 'definitions')/*">
            <xsl:call-template name="definition"/>
        </xsl:for-each>
        <xsl:for-each select="json:get($descriptor, 'paths')/*">
            <xsl:call-template name="path"/>
        </xsl:for-each>
        <xsl:result-document href="generated/map.dita" format="map">
            <map>
                <xsl:call-template name="intro">
                    <xsl:with-param name="info" select="json:get($descriptor, 'info')"></xsl:with-param>
                </xsl:call-template>
                <topichead navtitle="Endpoints">
                    <xsl:for-each select="json:get($descriptor, 'paths')/*">
                        <xsl:for-each select="./*">
                            <topicref href="{concat(json:get(., 'operationId')/text(), '-', @key, '.dita')}"/>
                        </xsl:for-each>
                    </xsl:for-each>
                </topichead>
                <topichead navtitle="Resources">
                    <xsl:for-each select="json:get($descriptor, 'definitions')/*">
                        <topicref href="{concat('schema-', @key, '.dita')}"/>
                    </xsl:for-each>
                </topichead>
            </map>
        </xsl:result-document>
    </xsl:template>
    
    <!-- Generate DITA content for an OpenAPI definition. -->
    <xsl:template name="definition">
        <xsl:variable name="id" select="concat('schema-', ./@key)"/>
        <xsl:result-document href="{concat('generated/', $id, '.dita')}" format="topic">
            <!-- TODO: Parameterized output file. --> 
            <topic>
                <xsl:attribute name="id" select="$id"/>
                <title>Data type: <xsl:value-of select="./@key"/></title>
                <body>
                    <xsl:variable name="props" select="json:get(., 'properties')/*"/>
                    <xsl:if test="not(empty($props))">
                        <dl>
                           <xsl:for-each select="$props">
                               <xsl:variable name="type" select="json:prop-type(.)"/>
                               <dlentry>
                                   <dt>
                                       <xsl:value-of select="./@key"/>
                                       <xsl:if test="not(empty($type))">
                                           (<xsl:copy-of select="$type"/>)
                                       </xsl:if>
                                   </dt>
                                   <dd><xsl:value-of select="json:get(., 'description')"/></dd>
                                   
                               </dlentry>
                           </xsl:for-each>                    
                        </dl>
                    </xsl:if>
                </body>
            </topic>
        </xsl:result-document>
    </xsl:template>
    
    <!-- Determine the type of an OpenAPI property. -->
    <xsl:function name="json:prop-type">
        <xsl:param name="prop"></xsl:param>
        <xsl:variable name="type" select="json:get($prop, 'type')"/>
        <xsl:variable name="schema_ref" select="json:get($prop, '$ref')"/>
        
        <xsl:choose>
            <xsl:when test="$type = 'array'">Array of <xsl:copy-of select="json:prop-type(json:get($prop, 'items'))"/></xsl:when>
            <xsl:when test="not(empty($type))"><xsl:value-of select="$type"/></xsl:when>
            <xsl:when test="not(empty($schema_ref))">
                <xsl:variable name="schema-name" select="substring-after($schema_ref, '#/definitions/')"/>
                <xref>
                    <xsl:attribute name="href" 
                        select="concat('#schema-', $schema-name)"/>
                    <xsl:value-of select="$schema-name"/>
                </xref>        
            </xsl:when>
        </xsl:choose>
        
    </xsl:function>
    
    <!-- Generate intro an OpenAPI spec. -->
    <xsl:template name="intro">
        <xsl:param name="info"/>
        <title>
            <xsl:attribute name="id">api-title</xsl:attribute>
            <xsl:value-of select="json:get($info,'title')"/>
        </title>
    </xsl:template>

    <!-- Generate DITA for an OpenAPI path. -->
    <xsl:template name="path">
        <!-- For each method we generate a topic. -->
        <xsl:for-each select="./*">
            <xsl:call-template name="method"/>
        </xsl:for-each>
    </xsl:template>
    
    <!-- Generate DITA for an OpenAPI method. -->
    <xsl:template name="method">
        <xsl:variable name="topicId" 
            select="concat(json:get(., 'operationId')/text(), '-', @key)"/>
        <xsl:result-document href="{concat('generated/', $topicId, '.dita')}" format="topic">
            <topic>
                <xsl:attribute name="id"><xsl:value-of select="$topicId"/></xsl:attribute>
                <title>
                    <xsl:attribute name="id" select="concat($topicId, '-title')"/>
                    <xsl:value-of select="json:get(.,'summary')"/>
                </title>
                <shortdesc>
                    <xsl:attribute name="id" select="concat($topicId, '-shortdesc')"/>
                    <xsl:value-of select="json:get(.,'description')"/>
                </shortdesc>
                
                <xsl:call-template name="tags">
                    <xsl:with-param name="tags" select="json:get(., 'tags')/*"/>
                </xsl:call-template>
                <body>
                    <xsl:call-template name="params">
                        <xsl:with-param name="params" select="json:get(., 'parameters')/*"/>
                    </xsl:call-template>
                    <xsl:call-template name="responses">
                        <xsl:with-param name="responses" select="json:get(., 'responses')/*"/>
                    </xsl:call-template>
                </body>
            </topic>
        </xsl:result-document>
    </xsl:template>

    <!-- Generate DITA for OpenAPI responses of a method. -->
    <xsl:template name="responses">
        <xsl:param name="responses"/>
        <xsl:if test="count($responses) > 0">
            <section>
                <title>Responses</title>
                <dl>
                    <xsl:for-each select="$responses">
                        <dlentry>
                            <dt><xsl:value-of select="./@key"/></dt>
                            <dd>
                                <xsl:value-of select="json:get(., 'description')"/>
                            </dd>
                            <xsl:variable name="type" select="json:prop-type(json:get(., 'schema'))"/>
                            <xsl:if test="not(empty($type))">
                                <dd><xsl:copy-of select="$type"/></dd>
                            </xsl:if>
                        </dlentry>
                    </xsl:for-each>
                </dl>    
            </section>
        </xsl:if>
    </xsl:template>
    
    <!-- Generate DITA for OpenAPI params of a method. -->
    <xsl:template name="params">
        <xsl:param name="params"/>
        <xsl:if test="count($params) > 0">
            <section>
                <title>Parameters</title>
                <parml>
                    <xsl:for-each select="$params">
                        <plentry>
                            <pt><xsl:value-of select="json:get(.,'name')"/></pt>
                            <pd>
                                <xsl:call-template name="paramdesc">
                                    <xsl:with-param name="info" select="."></xsl:with-param>
                                </xsl:call-template>
                            </pd>
                        </plentry>
                    </xsl:for-each>
                </parml>    
            </section>
        </xsl:if>
    </xsl:template>

    <!-- Generate DITA for an OpenAPI method param. -->
    <xsl:template name="paramdesc">
        <xsl:param name="info"/>
        
        <xsl:variable name="type" select="json:get_param_type($info)"/>
        <xsl:variable name="required" select="json:get($info,'required')"/>
        <xsl:variable name="in" select="json:get($info,'in')"/>
        <xsl:variable name="description" select="json:get($info,'description')"/>
        
        <dl>
            <xsl:if test="not(empty($description))">
                <dlentry>
                    <dt>Description</dt>
                    <dd><xsl:value-of select="$description"/></dd>
                </dlentry>
            </xsl:if>
            
            <xsl:if test="not(empty($type))">
                <dlentry>
                    <dt>Data Type</dt>
                    <dd>
                        <xsl:copy-of select="$type"/>
                    </dd>
                </dlentry>
            </xsl:if>
            
            <xsl:if test="not(empty($required))">
                <dlentry>
                    <dt>Requied</dt>
                    <dd>yes</dd>
                </dlentry>
            </xsl:if>        
            
            <xsl:if test="not(empty($in))">
                <dlentry>
                    <dt>Parameter Type</dt>
                    <dd>
                        <xsl:choose>
                            <xsl:when test="$in = 'body'">Body parameter</xsl:when>
                            <xsl:when test="$in = 'path'">Path parameter</xsl:when>
                            <xsl:when test="$in = 'query'">Query parameter</xsl:when>
                        </xsl:choose>
                    </dd>
                </dlentry>
            </xsl:if>        
        </dl>
    </xsl:template>

    <!-- Function to generate DITA for the type of an OpenAPI param -->
    <xsl:function name="json:get_param_type">
        <xsl:param name="info"/>
        <xsl:variable name="type" select="json:get($info, 'type')"/>
        <xsl:variable name="schema_ref" select="json:get(json:get($info, 'schema'), '$ref')"/>
        
        <xsl:choose>
            <xsl:when test="$type = 'array'">
                Array of <xsl:copy-of select="json:prop-type(json:get($info, 'items'))"></xsl:copy-of>
            </xsl:when>
            <xsl:when test="not(empty($type))">
                <xsl:value-of select="$type"/>
            </xsl:when>
            <xsl:when test="$schema_ref and starts-with($schema_ref, '#/definitions/')">
                <xsl:variable name="schema-name"
                    select="substring-after($schema_ref, '#/definitions/')"/>
                <xref>
                    <xsl:attribute name="href" select="concat('#schema-', $schema-name)"/>
                    <xsl:value-of select="$schema-name"/>
                </xref>
            </xsl:when>
        </xsl:choose>

    </xsl:function>

    <!-- Generate the tags for an OpenAPI method. -->
    <xsl:template name="tags">
        <xsl:param name="tags"/>
        <xsl:if test="count($tags) > 0">
            <prolog>
                <metadata>
                    <keywords>
                        <xsl:for-each select="$tags">
                            <indexterm>
                                <xsl:value-of select="."/>
                            </indexterm>
                        </xsl:for-each>
                    </keywords>
                </metadata>
            </prolog>
        </xsl:if>
    </xsl:template>
    
    <!-- Utility function to get a JSON field. -->
    <xsl:function name="json:get">
        <xsl:param name="node"/>
        <xsl:param name="name"/>
        <xsl:copy-of select="$node/*[@key=$name]"/>
    </xsl:function>
        
</xsl:stylesheet>