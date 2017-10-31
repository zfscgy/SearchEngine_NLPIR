<%@page import="org.apache.lucene.search.highlight.*"%>
<%@page import="org.apache.lucene.analysis.Analyzer"%>
<%@page import="org.apache.lucene.index.memory.*" %>
<%@page import="org.apache.lucene.queries.*" %>

<%@ page language="java" contentType="text/html; charset=utf-8"
    pageEncoding="utf-8"
    
%>
<%@ page  import = "TextIndexer.*,org.apache.lucene.document.Document,Container.*,ZQuery.*"%>
<!DOCTYPE html PUBLIC "-//W3C//DTD HTML 4.01 Transitional//EN" "http://www.w3.org/TR/html4/loose.dtd">
<html>
<head>
	<meta http-equiv="Content-Type" content="text/html; charset=utf-8">
	<title>ZF Search Engine</title>
	
	<script language="javascript">
		//Global varibles
		var searchInput;
		var selectLow;
		var selectHigh;
		//using the encodeURI and decodeURI functions to pass Chinese Characters
		function getQueryString(name)
		{
		     var reg = new RegExp("(^|&)"+ name +"=([^&]*)(&|$)");
		     var r = window.location.search.substr(1).match(reg);
		     if(r!=null)return  decodeURI(r[2]); return null;
		}
	    function search()
	    {
	    	searchStr = searchInput.value;
	    	//var selectLow = document.getElementsByName("YearSelectLow")[0];
	    	var lowValue = selectLow.options[selectLow.selectedIndex].value;
	    	//var selectHigh = document.getElementsByName("YearSelectHigh")[0];
	    	var highValue = selectHigh.options[selectHigh.selectedIndex].value;
	    	if(parseInt(highValue)<parseInt(lowValue)) 
	    	{
	    		highValue = lowValue;
	    	}
	        window.location.href="index.jsp"+"?query="+encodeURI(searchStr) + "&ly=" + lowValue + "&hy=" + highValue;
		}
	    window.onload = function()
	    {	//Initialize the global varibles
	    	searchInput = document.getElementsByName("SearchInput")[0];
	    	selectLow = document.getElementsByName("YearSelectLow")[0];
	    	selectHigh = document.getElementsByName("YearSelectHigh")[0];
	    	
	    	
	    	searchInput.value = getQueryString("query");
	    	sl = getQueryString("ly");
	    	sh = getQueryString("hy");
	    	if(sl!=null)
	    	{
	    		selectLow.selectedIndex = parseInt(sl.substr(0,4)-2012)*10 + parseInt(sl.substr(4,6)) - 1;
	    	}
	    	if(sh!=null)
	    	{
	    		selectHigh.selectedIndex = parseInt(sh.substr(0,4)-2012)*10 + parseInt(sh.substr(4,6)) - 1;
	    	}
	    }
	</script>
	<style>
		.titlebox
		{
			margin-left:30px;
			font-size:20px;
		}
		.contentbox
		{
			margin-left:60px;
			font-size:16px;
		}
	</style>
</head>
<body>
	<div style="margin-left:30px">
		<text style="font-size:22px">ZF search Engine</text>
		<input type="text" name="SearchInput" style="height:40px;width:300px;display:inline-block;font-size:22px" />
		<input type="button" value="Search" style="height:40px;width:80px;display:inline-block;font-size:22px" onclick="search()"/>
		时间范围
		<select name="YearSelectLow" style="height:30px;width:100px;display:inline-block;font-size:16px">
			<%
				for(int y = 2012;y<2014;y++)
				{
					for(int i = 1;i<13;i++)
					{
						String year = Integer.toString(y);
						String month = Integer.toString(i);
						if(month.length()==1)
						{
							month = "0"+month;
						}
						out.write("<option value=" + year + month +">" + year + "年" + month + "月" +"</option>");
					}
				}
			%>
		</select>
		到
		<select name="YearSelectHigh" style="height:30px;width:100px;display:inline-block;font-size:16px">
		<%
				for(int y = 2012;y<2014;y++)
				{
					for(int i = 1;i<13;i++)
					{
						String year = Integer.toString(y);
						String month = Integer.toString(i);
						if(month.length()==1)
						{
							month = "0"+month;
						}
						out.write("<option value=" + year + month +">" + year + "年" + month + "月" +"</option>");
					}
				}
		%>
		</select>
	</div>
	<%
		SimpleQuery simpleQuery = new SimpleQuery();
		simpleQuery.InitQuery("index.index");
		String queryString = request.getParameter("query");
		String queryYMLow = request.getParameter("ly");
		String queryYMHigh = request.getParameter("hy");
		int ymLow = Integer.MIN_VALUE;
		int ymHigh = Integer.MAX_VALUE;
		try{
			if(queryYMLow!=null)
			{
				ymLow = Integer.parseInt(queryYMLow)*100;
			}
			if(queryYMHigh!=null)
			{
				ymHigh = Integer.parseInt(queryYMHigh)*100;
			}
		}
		catch(NumberFormatException ne)
		{
			out.println("<p> An Error has occured,Sorry... </p>");
		}
		if(queryString!=null)
		{

			simpleQuery.Search(new String[]{"title","content"},new String[] {queryString,queryString}, 
					new float[] {(float) 4.0, (float)1.0},new boolean[] {true,true},ymLow,ymHigh+1,0);//+1 for the upperbound!
			Analyzer nta = simpleQuery.nta;
			QueryScorer scorer = new QueryScorer(simpleQuery.currentQuery);
			Highlighter highlighter = new Highlighter(scorer);
			Fragmenter fragmenter = new SimpleSpanFragmenter(scorer);
			highlighter.setTextFragmenter(fragmenter);
			
			for(int i = 0;i<simpleQuery.GetResultCount();i++)
			{
				Document result = simpleQuery.GetResults(i);
				String docTitle = result.get("title");
				String titleFragment = highlighter.getBestFragment(nta, "title", docTitle);
				String docContent = result.get("content");
				String contentFragment = highlighter.getBestFragment(nta, "content", docContent);
				out.println("<div class=\"titlebox\"><p><a href=" + result.get("url") +">" + titleFragment+"</a></p></div>");
				out.println("<div classs=\"contentbox\"><p>" + contentFragment + "</p></div>");
			}
		}
	%>
</body>
</html>