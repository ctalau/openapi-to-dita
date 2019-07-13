<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:xs="http://www.w3.org/2001/XMLSchema"
    exclude-result-prefixes="xs"
    version="2.0">
    
    <xsl:template name="main">
        <xsl:variable name="descriptor" select="json-to-xml(unparsed-text('sample/fusion.json'))"/>
        <dita>
            <xsl:value-of select="$descriptor//*[@key='title']"/>
        </dita>
    </xsl:template>
</xsl:stylesheet>