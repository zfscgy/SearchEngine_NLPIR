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
	        window.location.href="index.jsp"+"?query="+encodeURI(searchStr) + "&ly=" + lowValue + "&hy=" + highValue + "&p=0&c=0";
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
		.mainBody
		{
			height:auto!important; 
			height:100px; 
			min-height:100px
		}
		.titlebox
		{
			margin-left:30px;
			font-size:20px
		}
		.contentbox
		{
			margin-left:60px;
			font-size:16px;
			width:70%
		}
		.foot
		{
			text-align:center;
			font-size:12px;
		}
		em
		{
			font-style:normal;
			color:red
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
	<!-- simple query is a global var -->
	<%!
		SimpleQuery simpleQuery= new SimpleQuery();  
		int resultPerPage = 13;
	%>
	<div class="mainBody">
	<%
		simpleQuery.InitQuery("index113.index");
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
			//Those are just for highlighting!!!
			Analyzer nta = simpleQuery.nta;
			QueryScorer scorer = new QueryScorer(simpleQuery.currentQuery);
			SimpleHTMLFormatter formatter=new SimpleHTMLFormatter("<em>", "</em>");
			Highlighter highlighter = new Highlighter(formatter,scorer);
			Fragmenter fragmenter = new SimpleSpanFragmenter(scorer);
			highlighter.setTextFragmenter(fragmenter);
			int currentPage = Integer.parseInt(request.getParameter("p"));
			for(int i = currentPage * resultPerPage;i<(currentPage+1) * resultPerPage&& i <simpleQuery.GetResultCount();i++)
			{
				Document result = simpleQuery.GetResults(i);
				String docTitle = result.get("title");
				String titleFragment = highlighter.getBestFragment(nta, "title", docTitle);
				String docContent = result.get("content").replace(" ","");
				String contentFragment = highlighter.getBestFragment(nta, "content", docContent);
				out.println("<div class=\"titlebox\"><p><a href=" + result.get("url") +">" + titleFragment+"</a></p></div>");
				out.println("<div class=\"contentbox\"><p>" +"时间:"+ result.get("sdate") +"</p><p>"+ contentFragment + "</p></div>");
			}
		}
	%>
	</div>
	<div class="pages"><p>
	<%
		int pageNum;
		try{
			pageNum = simpleQuery.GetResultCount()/13 + 1;
		}
		catch(Exception e)
		{
			pageNum = 0;
		}
		int currentPage = (request.getParameter("p") != null)?Integer.parseInt(request.getParameter("p")):0;
		if(request.getParameter("p") != null)
		{
			String requestStr = request.getRequestURL() + "?" +request.getQueryString();
			String[] requestStrArr = requestStr.split("&");
			String newRequestStr = "";
			for(int i = 0;i<requestStrArr.length - 2;i++)
			{
				newRequestStr += requestStrArr[i];
				newRequestStr += "&";
			}
			for(int i = currentPage -5;i<currentPage+5 && i<pageNum;i++)
			{
				if(i >= 0&&i!=currentPage)
				{
					out.println("<a href=\""+ newRequestStr + "p=" + Integer.toString(i)
						+ "&c=1\">" + "   " +  Integer.toString(i + 1) + "</a>");
				}
				if(i==currentPage)
				{
					out.println("<em>" + Integer.toString(i+1) + "</em>");
				}
			}
		}
	%>
	</p>
	</div>
	<div class="foot">copyright @2017 Zheng Fei, University of Science and Technology of China</div>
</body>
</html>