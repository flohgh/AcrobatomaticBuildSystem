<?xml version="1.0" encoding="iso-8859-1"?>
<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
<xsl:output method="xml"
	    encoding="utf-8"
	    doctype-public="-//W3C//DTD XHTML 1.0 Transitional//EN"
		doctype-system="http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd"
	    indent="yes"/>
<!-- parametres :
	@buildDate : date d'invocation
-->
<xsl:param name="app"/>
<xsl:param name="version"/>
<xsl:param name="date"/>
<xsl:param name="user"/>
<xsl:param name="host"/>
<xsl:param name="srcdir"/>
<xsl:param name="mainCss">style.css</xsl:param>
<xsl:param name="slidesCss">slides.css</xsl:param>
<xsl:param name="context">Component <xsl:value-of select="$app"/>-<xsl:value-of select="$version"/></xsl:param>
<xsl:param name="root">.<xsl:call-template name="getbackpath">
  <xsl:with-param name="in"><xsl:value-of select="$srcdir"/></xsl:with-param> 
</xsl:call-template></xsl:param>
<xsl:param name="hasToc"><xsl:value-of select="count(/document/section)&gt;2"/></xsl:param>
<xsl:param name="buildinfo"><xsl:value-of select="$date"/> / <xsl:value-of select="$user"/>@<xsl:value-of select="$host"/></xsl:param>

<!--********************************************
!-->
<xsl:template name="getbackpath">
   <xsl:param name="in"/>
   <xsl:choose>
     <xsl:when test="contains($in,'/')">/..<xsl:call-template name="getbackpath">
       <xsl:with-param name="in"><xsl:value-of select="substring-after($in,'/')"/></xsl:with-param>
     </xsl:call-template></xsl:when>
     <xsl:otherwise></xsl:otherwise>
   </xsl:choose>
</xsl:template>     
<!--********************************************
	Structures de base
-->	
<xsl:template match="*">
  <xsl:param name="ename"><xsl:value-of select="name()"/></xsl:param>
  <xsl:element name="{$ename}"><xsl:apply-templates/></xsl:element>
</xsl:template>
<xsl:template match="a">
 <xsl:copy-of select="."/>
</xsl:template>
<xsl:template match="tr">
<xsl:choose>
   <!-- TODO understand why position() returns 2, 4, 6, 8, etc... 
        div 2 should not be needed -->
    <xsl:when test="(position() div 2) mod 2 = 0"><tr class="even"><xsl:apply-templates/></tr></xsl:when>
    <xsl:otherwise><tr class="odd"><xsl:apply-templates/></tr></xsl:otherwise>
</xsl:choose>
</xsl:template>
<xsl:template match="para">
    <p><xsl:apply-templates/></p>
</xsl:template>
<xsl:template match="em">
<i><xsl:apply-templates/></i>
</xsl:template>
<xsl:template match="kw">
<code><xsl:apply-templates/></code>
</xsl:template>
<xsl:template match="ul">
<ul>
	<xsl:apply-templates select="*"/>
</ul>
</xsl:template>
<xsl:template match="icode">
	<code><xsl:apply-templates/></code>
</xsl:template>	
<xsl:template match="table">
<xsl:param name="num"><xsl:value-of select="count(preceding::table)+1"/></xsl:param>
<div class="table">
<xsl:if test="@xref!=''"><a name="{@xref}"/></xsl:if>
<xsl:if test="@title!=''">
<a name="table-{$num}">
	<p>Table <xsl:value-of select="$num"/> - <xsl:value-of select="@title"/></p>
</a>
</xsl:if>
<table>
<xsl:apply-templates/>
</table>
</div>
</xsl:template>
<xsl:template match="todo">
<span class="todo"><xsl:apply-templates/></span>
</xsl:template>
<!--******************************
	Boite/cadre
-->
<xsl:template match="box|note">
	<xsl:param name="type"><xsl:choose>
	<xsl:when test="@type!=''"><xsl:value-of select="@type"/></xsl:when>
	<xsl:otherwise>info</xsl:otherwise>
</xsl:choose></xsl:param>
	<div class="{$type}">
<xsl:if test="@title!=''">
<p class="title"><xsl:value-of select="@title"/></p>
</xsl:if>
<xsl:apply-templates/></div>
</xsl:template>
<xsl:template match="code">
<xsl:param name="num"><xsl:value-of select="count(preceding::code)+1"/></xsl:param>
  	<div class="code">
		<xsl:if test="@title!=''">
			<p>Listing <xsl:value-of select="$num"/> - <xsl:value-of select="@title"/></p>
		</xsl:if>
		<a name="code-{$num}" class="noHoverable"/>
		<pre><code class="{@language}"><xsl:apply-templates select="pre/text()"/></code></pre>
	</div>	
</xsl:template>

<!--******************************
	inclusion d'un fichier texte
-->
<xsl:template match="text">
<pre>
include(<xsl:value-of select="@src"/>.txt)
</pre>
</xsl:template>
<!--******************************
	enumeration
-->	
<xsl:template match="enum">
	<xsl:if test="name(preceding-sibling::*[1])!='enum'">
		<xsl:apply-templates mode="acc" select="."/>
	</xsl:if>
</xsl:template>	
<!-- accumulation -->
<xsl:template match="enum" mode="acc">
	<xsl:param name="acc"/>
	<xsl:choose>
		<xsl:when test="name(following-sibling::*[1])!='enum'">
			<xsl:call-template name="enumEnd">
				<xsl:with-param name="acc">
					<xsl:copy-of select="$acc"/>
					<xsl:apply-templates mode="ok" select="."/>
				</xsl:with-param>
			</xsl:call-template>
		</xsl:when>
		<xsl:otherwise>
			<xsl:apply-templates select="following-sibling::*[1]" mode="acc">
				<xsl:with-param name="acc">
					<xsl:copy-of select="$acc"/>
					<xsl:apply-templates mode="ok" select="."/>
				</xsl:with-param>
			</xsl:apply-templates>
		</xsl:otherwise>
	</xsl:choose>
</xsl:template>
<!-- ok -->
<xsl:template match="enum" mode="ok">
	<li><xsl:apply-templates/></li>
</xsl:template>
<!-- copier le resultat indent� -->
<xsl:template name="enumEnd">
	<xsl:param name="acc"/>
	<ul>
		<xsl:copy-of select="$acc"/>
	</ul>
</xsl:template>
<!--***********************************************
	Figure
-->
<xsl:template match="fig">
<xsl:param name="num"><xsl:value-of select="count(preceding::fig)+1"/></xsl:param>
	<div class="fig">
<xsl:if test="@xref!=''"><a name="{@xref}"/></xsl:if>
	<a name="fig-{$num}" href="{@src}"><img src="{@src}" alt="{@title}"/></a>
<xsl:if test="@title!=''">
	<br/>
	Figure <xsl:value-of select="$num"/> - <xsl:value-of select="@title"/>
</xsl:if>
	</div>
</xsl:template>
<!--************************************************
     	requirements
-->
<xsl:template match="req">
<div class="req">
<table><tr>
<th><a name="req.{@id}"><xsl:value-of select="@id"/></a></th><td><xsl:value-of select="."/></td> 
</tr></table>
</div>
</xsl:template>
<xsl:template match="req" mode="ref">
  <xsl:param name="rid"><xsl:value-of select="text()"/></xsl:param>
  <a href="#req.{$rid}"><xsl:value-of select="$rid"/></a>
</xsl:template>
<!-- traceability -->
<xsl:template match="index[@type='req']">
  <table>
  <tr><th>Requirement</th><th>Referenced by</th></tr>
  <xsl:apply-templates select="/document/section//req" mode="index"/>
  </table>
</xsl:template>
<xsl:template match="req" mode="index">
<xsl:if test="@id!=''">
  <xsl:variable name="rid"><xsl:value-of select="@id"/></xsl:variable>
  <xsl:variable name="trclass"><xsl:choose>
	<xsl:when test="(position() + 1) mod 2 = 0">even</xsl:when>
	<xsl:otherwise>odd</xsl:otherwise>
  </xsl:choose></xsl:variable>
  <tr class="{$trclass}"><td><a href="#req.{@id}"><xsl:value-of select="@id"/></a></td><td>
    <xsl:choose>
      <xsl:when test="count(//req[text()=$rid])&gt;0">
	<xsl:apply-templates select="//req[text()=$rid]/.." mode="index"/>
      </xsl:when>
      <xsl:otherwise>No reference.</xsl:otherwise>
    </xsl:choose>
  </td></tr>  
</xsl:if>
</xsl:template>
<xsl:template match="*" mode="index">
<xsl:param name="num"><xsl:number count="section|references|definitions" level="multiple" format="1.1"/></xsl:param>
<a href="#{$num}"><xsl:value-of select="$num"/></a>
</xsl:template>
<xsl:template match="check" mode="index">
<xsl:param name="num"><xsl:number count="section|references|definitions|check" level="multiple" format="1.1"/></xsl:param>
  Check <a href="#{$num}"><xsl:value-of select="$num"/></a>
</xsl:template>
<xsl:template match="assert" mode="index">
<xsl:param name="num"><xsl:number count="section|references|definitions|check|assert" level="multiple" format="1.1"/></xsl:param>
  Assert <a href="#{$num}"><xsl:value-of select="$num"/></a>
</xsl:template>
<!--************************************************
    Checks
-->
<xsl:template match="check">
<xsl:call-template name="sectionHead">
	<xsl:with-param name="title">Control procedure <xsl:value-of select="@id"/> - <xsl:value-of select="@title"/></xsl:with-param> 
	<xsl:with-param name="level"><xsl:value-of select="count(ancestor-or-self::section)+count(ancestor-or-self::article)+2"/></xsl:with-param> 
	<xsl:with-param name="xref"><xsl:value-of select="@xref"/></xsl:with-param> 
</xsl:call-template>	
<xsl:if test="count(req)&gt;0">
<div class="chkreq">
<h5>Checked requirements</h5>
 <xsl:apply-templates select="req" mode="ref"/>
</div>
</xsl:if>
<xsl:apply-templates select="*[not(self::req)]"/>
</xsl:template>
<xsl:template match="operation">
<div class="operation">
<h5>Operation #<xsl:value-of select="count(preceding-sibling::operation)+1"/> <xsl:value-of select="@id"/> <xsl:value-of select="@title"/></h5>
  <xsl:apply-templates/>
</div>
</xsl:template>
<xsl:template match="assert">
  <xsl:param name="aid"><xsl:number count="section|references|definitions|check|assert" level="multiple" format="1.1"/></xsl:param>
<div class="assert">
<h5><a name="{$aid}">Assert #<xsl:value-of select="count(preceding-sibling::assert)+1"/></a> <xsl:value-of select="@id"/> <xsl:value-of select="@title"/></h5>
<xsl:apply-templates select="*[not(self::req)]"/>
<xsl:if test="count(req)&gt;0">
<b>Checks:</b> <xsl:apply-templates select="req" mode="ref"/>
</xsl:if>
</div>
</xsl:template>
<!--************************************************
     Definition table
-->
<xsl:template match="definitions">
<xsl:call-template name="sectionHead">
	<xsl:with-param name="title"><xsl:value-of select="@title"/></xsl:with-param> 
	<xsl:with-param name="level"><xsl:value-of select="count(ancestor-or-self::section)+count(ancestor-or-self::article)+2"/></xsl:with-param> 
	<xsl:with-param name="xref"><xsl:value-of select="@xref"/></xsl:with-param> 
</xsl:call-template>	
<table class="def">
<xsl:apply-templates select="def">
  <xsl:sort select="@entry"/>
</xsl:apply-templates>
</table>
</xsl:template>
<xsl:template match="def">
  <xsl:param name="trclass"><xsl:choose>
	<xsl:when test="(position() div 2 + 1) mod 2 = 0">even</xsl:when>
	<xsl:otherwise>odd</xsl:otherwise>
  </xsl:choose></xsl:param>
<tr class="{$trclass}"><th><xsl:value-of select="@entry"/></th><td><xsl:apply-templates/></td></tr>
</xsl:template>
<!--************************************************
     Reference table
-->
<xsl:template match="references">
<xsl:call-template name="sectionHead">
	<xsl:with-param name="title"><xsl:value-of select="@title"/></xsl:with-param> 
	<xsl:with-param name="level"><xsl:value-of select="count(ancestor-or-self::section)+count(ancestor-or-self::article)+2"/></xsl:with-param> 
	<xsl:with-param name="xref"><xsl:value-of select="@xref"/></xsl:with-param> 
</xsl:call-template>	
<table class="ref">
<tr><th> </th><th>Authors <i>Title</i><br/>Reference <i>Edition</i></th></tr>
<xsl:apply-templates/>
</table>
</xsl:template>
<xsl:template match="ref">
  <xsl:param name="hhref"><xsl:value-of select="@href"/></xsl:param>
  <xsl:param name="trclass"><xsl:choose>
	<xsl:when test="(position() div 2 + 1) mod 2 = 0">even</xsl:when>
	<xsl:otherwise>odd</xsl:otherwise>
  </xsl:choose></xsl:param>
<tr class="{$trclass}"><th><a name="{@id}"/><xsl:value-of select="../@id"/><xsl:value-of select="count(preceding-sibling::ref)+1"/></th>
   <td><xsl:value-of select="@authors"/>&#160;<i>
    <xsl:choose>
      <xsl:when test="$hhref=''">
        "<xsl:apply-templates/>"
      </xsl:when>
      <xsl:otherwise>
        <a href="{@href}">"<xsl:apply-templates/>"</a>
      </xsl:otherwise>
    </xsl:choose>
     </i><br/>
      <xsl:value-of select="@ref"/>&#160;<i><xsl:value-of select="@edition"/>&#160;<xsl:value-of select="@date"/></i></td>
</tr>
</xsl:template>
<xsl:template match="ref" mode="xref">
  <xsl:param name="hhref"><xsl:value-of select="@href"/></xsl:param>
  <span class="xref"><xsl:attribute name="title"><xsl:value-of select="@authors"/>: <xsl:value-of select="text()"/></xsl:attribute><xsl:choose><xsl:when test="$hhref=''"><xsl:value-of select="../@id"/><xsl:value-of select="count(preceding-sibling::ref)+1"/></xsl:when><xsl:otherwise><a href="{@href}"><xsl:value-of select="../@id"/><xsl:value-of select="count(preceding-sibling::ref)+1"/></a></xsl:otherwise></xsl:choose></span>
</xsl:template>
<!-- ************************************************************************
    Cross reference
-->
<xsl:template match="xref">
<xsl:param name="refvalue"><xsl:value-of select="text()"/></xsl:param>
<xsl:apply-templates select="//*[@xref=$refvalue]" mode="xref"/>
<xsl:apply-templates select="//ref[@id=$refvalue]" mode="xref"/>
</xsl:template>
<xsl:template match="section|references|definitions|check|operation|assert" mode="xref">
<xsl:param name="num"><xsl:number count="section|references|definitions|check|operation|assert" level="multiple" format="1.1"/></xsl:param>
<a href="#{$num}"><xsl:value-of select="$num"/></a>
</xsl:template>
<xsl:template match="table" mode="xref">
<xsl:param name="num"><xsl:number count="table"/></xsl:param>
<a href="#table-{$num}"><xsl:value-of select="$num"/></a>
</xsl:template>
<xsl:template match="fig" mode="xref">
<xsl:param name="num"><xsl:number count="fig"/></xsl:param>
<a href="#fig-{$num}"><xsl:value-of select="$num"/></a>
</xsl:template>
<xsl:template match="code" mode="xref">
<xsl:param name="num"><xsl:number count="code"/></xsl:param>
<a href="#code-{$num}"><xsl:value-of select="$num"/></a>
</xsl:template>
<!--***********************************************
	Auteur
-->
<xsl:template match="author" mode="refDetail">
	<xsl:apply-templates/><xsl:text>, </xsl:text>
</xsl:template>
<!--***********************************************
	URL
-->
<xsl:template match="href" mode="refDetail">
	<br/><a target="_top">
		<xsl:attribute name="href"><xsl:value-of select="."/></xsl:attribute>
		<xsl:apply-templates/>
	</a>
</xsl:template>	
<!--***********************************************
	copie "bete" du contenu d'un bloc xhtml
-->
<xsl:template match="xhtml">
	<xsl:copy-of select="./*"/>
</xsl:template>	
<!--************************************************
	Resum�/Description de page
-->
<xsl:template match="abstract">
	<meta name="description">
		<xsl:attribute name="content"><xsl:apply-templates/></xsl:attribute>
	</meta>
</xsl:template>
<xsl:template match="abstract" mode="show">
	<div class="abstract">
	<h2>Abstract</h2>
	<p><xsl:apply-templates/></p>
	</div>
</xsl:template>
<xsl:template match="keywords" mode="show">
	<div class="keywords">
	<h2>Keywords</h2>
	<p><xsl:apply-templates/></p>
	</div>
</xsl:template>
<xsl:template match="history">
	<div class="history">
	<h2>History</h2>
	<table class="history">
	<tr>
	<th>Issue</th><th>Date</th><th>Changes</th>
	</tr>
	<xsl:apply-templates/>
	</table>
	</div>
</xsl:template>
<xsl:template match="edition">
  <xsl:param name="trclass"><xsl:choose>
	<xsl:when test="(position() div 2 + 1) mod 2 = 0">even</xsl:when>
	<xsl:otherwise>odd</xsl:otherwise>
  </xsl:choose></xsl:param>
<tr class="{$trclass}">
  <td><xsl:apply-templates select="@version"/></td>
  <td><xsl:apply-templates select="@date"/></td>
  <td><xsl:apply-templates/></td>
</tr>
</xsl:template>

<!--************************************************
	mots cl�s
-->
<xsl:template match="keywords">
	<meta name="keywords">
		<xsl:attribute name="content"><xsl:apply-templates/></xsl:attribute>
	</meta>
</xsl:template>
<!--************************************************
	tete de section
		$id id de la section
		$title titre de la section
		$level niveau de section
-->
<xsl:template name="sectionHead">
	<xsl:param name="id">none</xsl:param>
	<xsl:param name="title"></xsl:param>
	<xsl:param name="level">2</xsl:param>
	<xsl:param name="xref">none</xsl:param>
	<div class="section-head">
		<xsl:if test="$xref!=''"><a name="{$xref}"></a></xsl:if>
	<xsl:choose>
		<xsl:when test="$title=''">&#160;</xsl:when>
		<xsl:otherwise>
			<xsl:element name="h{$level}">
				<xsl:if test="$id!='none'">
					<a name="{$id}"><xsl:value-of select="$id"/></a>
				</xsl:if>
				<xsl:if test="$hasToc!=0">
				<a><xsl:attribute name="name">
					<xsl:number count="section|references|definitions|check" level="multiple" format="1.1"/>
				</xsl:attribute></a>
				<a href="#top">
					<xsl:number count="section|references|definitions|check" level="multiple" format="1.1"/></a>&#160;
				</xsl:if>	
				<xsl:value-of select="$title"/>
			</xsl:element>	
		</xsl:otherwise>
	</xsl:choose>
	</div>
</xsl:template>
<!--************************************************
	Prise en charge d'une section
-->	
<xsl:template match="section">
	<div class="section">
	<xsl:choose>
		<xsl:when test="count(ancestor::chapter)&gt;0">
			<xsl:call-template name="sectionHead">
				<xsl:with-param name="id"><xsl:number level="multiple" count="section|article"/></xsl:with-param> 
				<xsl:with-param name="title"><xsl:value-of select="@title"/></xsl:with-param> 
				<xsl:with-param name="level"><xsl:value-of select="count(ancestor-or-self::section)+count(ancestor-or-self::article)+1"/></xsl:with-param> 
				<xsl:with-param name="xref"><xsl:value-of select="@xref"/></xsl:with-param> 
			</xsl:call-template>	
		</xsl:when>
		<xsl:otherwise>
			<xsl:call-template name="sectionHead">
				<xsl:with-param name="title"><xsl:value-of select="@title"/></xsl:with-param> 
				<xsl:with-param name="level"><xsl:value-of select="count(ancestor-or-self::section)+count(ancestor-or-self::article)+1"/></xsl:with-param> 
				<xsl:with-param name="xref"><xsl:value-of select="@xref"/></xsl:with-param> 
			</xsl:call-template>	
		</xsl:otherwise>
	</xsl:choose>
	<xsl:apply-templates/>
	</div>
</xsl:template>
<!--****************************************************
	Table des mati�res
-->
<xsl:template match="section|references|definitions" mode="summary">
<xsl:param name="num"><xsl:number count="section|references|definitions|check" level="multiple" format="1.1"/></xsl:param>
	<li><a href="#{$num}"><xsl:value-of select="$num"/>&#160;<xsl:value-of select="@title"/></a>
	<xsl:if test="count(section|references|definitions|check)&gt;0">
		<ul>
			<xsl:apply-templates select="section|references|definitions|check" mode="summary"/>
		</ul>
	</xsl:if>
	</li>
</xsl:template>
<xsl:template match="check" mode="summary">
<xsl:param name="num"><xsl:number count="section|references|definitions|check" level="multiple" format="1.1"/></xsl:param>
	<li><a href="#{$num}"><xsl:value-of select="$num"/>&#160;Control procedure <xsl:value-of select="@id"/> <xsl:value-of select="@title"/></a>
	</li>
</xsl:template>
<xsl:template name="toc">
<div class="toc">
<h3>Summary</h3>
<ul>
<xsl:apply-templates select="/document/section" mode="summary"/>
</ul>
</div>
<br/>
<xsl:apply-templates select="/document/abstract" mode="show"/>
<xsl:apply-templates select="/document/keywords" mode="show"/>
<xsl:apply-templates select="/document/history"/>
</xsl:template>

<xsl:template match="package">
<p><xsl:apply-templates/>.</p>
</xsl:template>

<!-- #######################################################
	index document
<xsl:template match="index">
<div class="index">
<table>
	<xsl:apply-templates/>
</table>
</div>
</xsl:template>
<xsl:template match="document">
<tr>
<td valign="top"><a href="{content/@file}">
	<xsl:value-of select="ref"/>
</a></td>
<td>
	<xsl:apply-templates select="title"/>
	<xsl:apply-templates select="att"/>
</td>
</tr>
</xsl:template>
<xsl:template match="att">
	<li><xsl:apply-templates/> <a href="{@file}">[Ouvrir]</a></li> 
</xsl:template>
-->
<!-- #######################################################
	blog
-->
<xsl:template match="blog">
<div class="blog">
	<xsl:apply-templates select="document(@index)/blog/entry"/> 
</div>
</xsl:template>
<xsl:template match="entry">
<div class="blog-entry">
	<div class="blog-entry-head">
		<h2><xsl:value-of select="@title"/></h2>
		<p><xsl:value-of select="@author"/>, <xsl:value-of select="@date"/></p>
	</div>
	<div class="blog-entry-content">
		<xsl:apply-templates/>
	</div>
</div>
</xsl:template>

<!-- #######################################################
	en tete de page
-->
<xsl:template match="parent">
/ <a href="{@path}"><xsl:value-of select="@title"/></a>
</xsl:template>
<xsl:template match="subdir|subfile">
| <a href="{@path}"><xsl:value-of select="@title"/></a>
</xsl:template>
<xsl:template name="page-head">
	<xsl:param name="title"></xsl:param>
<div class="head">
	<xsl:apply-templates select="head"/>
<h1><a name="top"><xsl:value-of select="$title"/></a></h1>
<p aligh="right"><xsl:value-of select="/document/author/@sigle"/> n�<xsl:value-of select="/document/reference"/>, Issue <xsl:value-of select="/document/history/edition[1]/@version"/> - Revision <xsl:value-of select="/document/revision"/> - <xsl:value-of select="/document/history/edition[1]/@date"/></p>
</div>
</xsl:template>
<!-- #######################################################
	corps de page
-->
<xsl:template name="page-body">
	<xsl:param name="content-template"></xsl:param>
<div class="body">
	<xsl:if test="$hasToc!=0">
		<xsl:call-template name="toc"/>
	</xsl:if>
<xsl:choose>
	<xsl:when test="$content-template='section'">
		<xsl:apply-templates select="toc|section|xhtml"/>
	</xsl:when>
	<xsl:otherwise>
		<xsl:apply-templates/>
	</xsl:otherwise>
</xsl:choose>	
</div>
</xsl:template>
<!-- #######################################################
	pied de page
-->
<xsl:template name="page-foot">
<div class="foot">
<p><xsl:apply-templates select="/document/copyright"/>Context: <xsl:value-of select="$context"/> - Generated: <xsl:value-of select="$buildinfo"/></p>
</div>
</xsl:template>
<xsl:template match="copyright">
Copyright (c) <xsl:value-of select="./text()"/> <xsl:value-of select="@year"/><xsl:text> </xsl:text><xsl:value-of select="@holder"/>,&#160;
</xsl:template>
<!-- #######################################################
	squelette page
-->
<xsl:template name="page">
	<xsl:param name="title"></xsl:param>
	<xsl:param name="content-template"></xsl:param>
<html xmlns="http://www.w3.org/1999/xhtml" xml:lang="fr" lang="fr">
<head>
<meta http-equiv="Content-Type" content="text/html; charset=utf-8" />
<title><xsl:value-of select="$title"/></title>
<xsl:apply-templates select="abstract"/>
<xsl:apply-templates select="keywords"/>
<link rel="stylesheet" href="./highlight/default.css"/>
<script src="{$root}/highlight/highlight.js">
&#160;
</script>
<script>hljs.initHighlightingOnLoad();</script>
<link rel="stylesheet" href="{$root}/{$mainCss}"/>
</head>	
<body>
	<a name="top"/>
<!-- en tete page -->
<xsl:call-template name="page-head">
	<xsl:with-param name="title"><xsl:value-of select="$title"/></xsl:with-param>
</xsl:call-template>
<!-- corps de la page -->
<xsl:call-template name="page-body">
	<xsl:with-param name="content-template"><xsl:value-of select="$content-template"/></xsl:with-param>
</xsl:call-template>
<!-- pied de page -->
<xsl:call-template name="page-foot"/>
</body>
</html>
</xsl:template>
<!-- #######################################################
	mapping root sur squelette page
-->
<xsl:template match="root">
	<xsl:call-template name="page">
		<xsl:with-param name="title" select="@title"/>
		<xsl:with-param name="content-template">all</xsl:with-param>
	</xsl:call-template>
</xsl:template>
<!-- #######################################################
	mapping document sur squelette page
-->
<xsl:template match="/document">
	<xsl:if test="count(section)&gt;0">
	<xsl:call-template name="page">
		<xsl:with-param name="title"><xsl:value-of select="title"/><xsl:value-of select="@title"/></xsl:with-param>
		<xsl:with-param name="content-template">section</xsl:with-param>
	</xsl:call-template>
	</xsl:if>
</xsl:template>
<!--**********************************************
	sommaire
-->
<xsl:template match="document" mode="summary">
	<div class="toc">
	<xsl:param name="chapterFile"/>
	<xsl:param name="id"/>
	<h3><a href="{$chapterFile}"> Chapitre&#160;<xsl:value-of select="$id"/>&#160;: 
		&#160;<xsl:value-of select="title"/></a></h3>
	<xsl:if test="count(section)&gt;0">
		<ul><xsl:apply-templates select="section" mode="summary">
			<xsl:with-param name="chapterFile"><xsl:value-of select="$chapterFile"/></xsl:with-param>
		</xsl:apply-templates></ul>
	</xsl:if>
	</div>
</xsl:template>
<xsl:template match="summary/include">
	<xsl:apply-templates select="document(concat(@href,'.xml'),/)/document" mode="summary">
		<xsl:with-param name="chapterFile"><xsl:value-of select="@href"/>.html</xsl:with-param>
		<xsl:with-param name="id"><xsl:number count="include" format="I"/></xsl:with-param>
	</xsl:apply-templates>
</xsl:template>
<!--
     ##########################################################################
                Presentation/slides transformations
     ##########################################################################
-->
<xsl:template match="section" mode="slide">
<xsl:apply-templates mode="slide"/>
</xsl:template>
<xsl:template match="slide" mode="slide">
<div class="step slide">
<xsl:choose>
  <xsl:when test="count(preceding-sibling::slide)=0">
    <xsl:attribute name="data-x">0</xsl:attribute>
    <xsl:attribute name="data-rel-y">1.25h</xsl:attribute>
  </xsl:when>
  <xsl:otherwise>
    <xsl:attribute name="data-rel-x">1.05w</xsl:attribute>
    <xsl:attribute name="data-rel-y">0</xsl:attribute>
  </xsl:otherwise>
</xsl:choose>
<h2><xsl:apply-templates select="@title"/></h2>
<xsl:apply-templates/>
</div>
</xsl:template>
<!-- layout handling, resize, multi column, ... -->
<xsl:template match="layout">
<div class="col{@col}">
<xsl:apply-templates/>
</div>
</xsl:template>
<!-- column break handling -->
<xsl:template match="break">
</xsl:template>
<xsl:template match="pnotes|pnote">
<div class="notes">
<xsl:apply-templates/>
</div>
</xsl:template>
<xsl:template match="speech">
<xsl:param name="toSpeech"><xsl:value-of select="."/></xsl:param>
<div class="speech">
<a href="#" onclick="speak('{$toSpeech}')">[Speech]</a>
</div>
</xsl:template>
<xsl:template match="titleImage">
<div class="fig">
<img><xsl:attribute name="src"><xsl:value-of select="text()"/></xsl:attribute></img>
</div>
</xsl:template>
<!-- Presentation main -->
<xsl:template match="/presentation">
<html xmlns="http://www.w3.org/1999/xhtml" xml:lang="fr" lang="fr">
<head>
<meta http-equiv="Content-Type" content="text/html; charset=utf-8" />
<title><xsl:value-of select="title"/><xsl:value-of select="@title"/></title>
<xsl:apply-templates select="abstract"/>
<xsl:apply-templates select="keywords"/>
<link rel="stylesheet" href="./highlight/default.css"/>
<script src="{$root}/highlight/highlight.js">
&#160;
</script>
<script>hljs.initHighlightingOnLoad();</script>
<link rel="stylesheet" href="{$root}/{$slidesCss}"/>
</head>	
<body>
<div id="impress">
<div class="step slide title" data-x="0" data-y="0" data-z="0" data-rel-x="0" data-rel-y="0" data-rel-z="0">
<h1><xsl:value-of select="title"/><xsl:value-of select="@title"/></h1>
<xsl:apply-templates select="titleImage"/>
</div>
<xsl:apply-templates select="section|slide" mode="slide"/>
<div id="overview" class="step" data-scale="10" data-x="4000" data-y="2000" data-z="10">
<xsl:text> </xsl:text>
</div>
</div>
<!-- pied de page -->
<div id="impress-toolbar"></div>
<div class="impress-progressbar"><div></div></div>
<div class="impress-progress"></div>
<div id="impress-help"></div>
<script type="text/javascript" src="{$root}/impress/impress.js">
<xsl:text> </xsl:text>
</script>
<script>
function speak(txt) {
	var u=new SpeechSynthesisUtterance();
	u.lang="en-US";
	u.text=txt;
	speechSynthesis.speak(u);
}

impress().init();
</script>
</body>
</html>
</xsl:template>

</xsl:stylesheet>
