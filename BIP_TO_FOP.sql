create or replace procedure convert_fo_template(p in out nocopy clob) 
 is
   v_region_before  varchar2(3000);
   v_region_body    varchar2(3000);
   v_region_after   varchar2(3000);
 begin
    -- tested with Oracle BI Publisher Desctop 11.1.1.6.2 Build 11.116.2.1
    
    -- del incompatible strings
    p:= replace(p,'<xsl:variable name="_XDOXSLTCTX" select="xdoxslt:set_xslt_locale($_XDOCTX, $_XDOLOCALE, $_XDOTIMEZONE, $_XDOCALENDAR, $_XDODFOVERRIDE, $_XDOCURMASKS, $_XDONFSEPARATORS)"/>','');
    p:= replace(p,'<fo:title>','');
    p:= replace(p,'<xsl:value-of select="xdoxslt:one($titlevar)" xdofo:field-name="$titlevar"/>','');
    p:= replace(p,'</fo:title>','');
    
    --replace xdoxslt:one() => number()
    p:= replace(p,'xdoxslt:one','number');

    -- del  xdofo: attributes
    -- <fo:root xdofo:nf-separator="{$_XDONFSEPARATORS}"> => <fo:root >    
    p := regexp_replace(p,'xdofo:(\w|[-])+="[^"]+"','');
    -- del xdofo: open and close tags
    -- <xdofo:property name="default-tab-width">35.4pt</xdofo:property> => NULL
    p := regexp_replace(p,'<xdofo:[^/]+/xdofo:(\w|[-])+>','');
    -- del standalone xdofo: tags
    -- <xdofo:properties> = > NULL
    p := regexp_replace(p,'</?xdofo:(\w|[-])+>','');
    --del empty <fo:static-content/>
    p := regexp_replace(p,'<fo:static-content[^>]+/>','');
    
    --remove other incompatible attributes
    p := regexp_replace(p,'style\-name="[^"]+"','');
    p := regexp_replace(p,'font\-family\-generic="[^"]+"','');
    p := regexp_replace(p,'style\-id="[^"]+"','');
    p := regexp_replace(p,'xml:space="[^"]+"','');

    /*
               <fo:region-before region-name="region-header" extent="35.45pt"/>
               <fo:region-body region-name="region-body" margin-top="35.45pt" margin-bottom="21.3pt"/>
               <fo:region-after region-name="region-footer" extent="21.3pt" display-align="after"/>
         =>
               <fo:region-body region-name="region-body" margin-top="35.45pt" margin-bottom="21.3pt"/>
               <fo:region-before region-name="region-header" extent="35.45pt"/>               
               <fo:region-after region-name="region-footer" extent="21.3pt" display-align="after"/>
   */   
   v_region_before  := regexp_substr(p,'<fo:region\-before .+/>');
   v_region_body    := regexp_substr(p,'<fo:region\-body .+/>');
   v_region_after   := regexp_substr(p,'<fo:region\-after .+/>');
   p := replace(p,v_region_before,'');
   p := replace(p,v_region_body,'');
   p := replace(p,v_region_after,v_region_body||v_region_before||v_region_after);
   
   --remove empty rows
   p := regexp_replace(p,'<fo:table-row>[^<]*<fo:table-cell [^/]*/>[^<]*</fo:table-row>','');  
   
 end convert_fo_template;
/