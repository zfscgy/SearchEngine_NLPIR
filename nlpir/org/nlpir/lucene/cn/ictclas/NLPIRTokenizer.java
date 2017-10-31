package org.nlpir.lucene.cn.ictclas;

import java.io.File;
import java.io.FileInputStream;
import java.io.FileNotFoundException;
import java.io.IOException;
import java.util.Properties;
import org.apache.lucene.analysis.Tokenizer;
import org.apache.lucene.analysis.tokenattributes.CharTermAttribute;
import org.apache.lucene.analysis.tokenattributes.OffsetAttribute;
import org.apache.lucene.analysis.tokenattributes.TypeAttribute;
import org.apache.lucene.util.AttributeFactory;
import org.nlpir.segment.CNLPIRLibrary;
import org.nlpir.segment.exception.NLPIRException;

/**
 * 
 * @author panhongyan
 *
 */
public class NLPIRTokenizer extends Tokenizer {

	private final CharTermAttribute termAtt = addAttribute(CharTermAttribute.class);
	private final OffsetAttribute offsetAtt = addAttribute(OffsetAttribute.class);
	private final TypeAttribute typeAtt = addAttribute(TypeAttribute.class);

	private String[] buffer = null;
	private StringBuffer cbuffer = null;
	int start = 0;
	int end = 0;
	int current = 0;

	String data=null;
	int encoding=1;
	String sLicenceCode=null;
	String userDict=null;
	boolean bOverwrite=false;
	
	public void defaultInit() {
		Properties prop=new Properties();
		try {
			prop.load(new FileInputStream(new File("nlpir.properties")));
			data=prop.getProperty("data");
			encoding=Integer.parseInt(prop.getProperty("encoding"));
			sLicenceCode=prop.getProperty("sLicenceCode");
			userDict=prop.getProperty("userDict");
			bOverwrite=Boolean.parseBoolean(prop.getProperty("bOverwrite"));
			System.out.println(data);
			System.out.println(encoding);
			System.out.println(sLicenceCode);
			System.out.println(userDict);
			System.out.println(bOverwrite);
		} catch (FileNotFoundException e) {
			e.printStackTrace();
		} catch (IOException e) {
			e.printStackTrace();
		}
	}
	//默认初始化方法
	public NLPIRTokenizer(AttributeFactory factory) {
		super(factory);
		this.defaultInit();
		this.init(data, encoding, sLicenceCode, userDict, bOverwrite);
	}
	
	/**
	 * 分词初始化
	 * 
	 * @param data
	 *            词典路径
	 * @param encoding
	 *            编码 0：GBK；1：UTF-8
	 * @param sLicenceCode
	 *            授权码，默认为""
	 * @param userDict
	 *            用户词典文件
	 * @param nOverwrite
	 *            用户词典引入方式
	 */
	public NLPIRTokenizer(String data, int encoding, String sLicenceCode, String userDict, boolean bOverwrite) {
		this.init(data, encoding, sLicenceCode, userDict, bOverwrite);
	}

	/**
	 * 分词初始化
	 * 
	 * @param data
	 *            词典路径
	 * @param encoding
	 *            编码 0：GBK；1：UTF-8
	 * @param sLicenceCode
	 *            授权码，默认为""
	 * @param userDict
	 *            用户词典文件
	 * @param nOverwrite
	 *            用户词典引入方式
	 */
	public NLPIRTokenizer(AttributeFactory factory, String data, int encoding, String sLicenceCode, String userDict,
			boolean bOverwrite) {
		super(factory);
		this.init(data, encoding, sLicenceCode, userDict, bOverwrite);
	}

	/**
	 * 分词初始化
	 * 
	 * @param data
	 *            词典路径
	 * @param encoding
	 *            编码 0：GBK；1：UTF-8
	 * @param sLicenceCode
	 *            授权码，默认为""
	 * @param userDict
	 *            用户词典文件
	 * @param nOverwrite
	 *            用户词典引入方式
	 */
	private void init(String data, int encoding, String sLicenceCode, String userDict, boolean bOverwrite) {
		boolean flag = CNLPIRLibrary.Instance.NLPIR_Init(data, encoding, sLicenceCode);
		if (!flag) {
			try {
				throw new NLPIRException(CNLPIRLibrary.Instance.NLPIR_GetLastErrorMsg());
			} catch (NLPIRException e) {
				e.printStackTrace();
			}
		} else if (userDict != null && !userDict.isEmpty()&&!userDict.equals("\"\"")) {
			int state = CNLPIRLibrary.Instance.NLPIR_ImportUserDict(userDict, bOverwrite);
			if (state == 0)
				try {
					throw new NLPIRException(CNLPIRLibrary.Instance.NLPIR_GetLastErrorMsg());
				} catch (NLPIRException e) {
					e.printStackTrace();
				}
		}
	}

	@Override
	public boolean incrementToken() throws IOException {
		if (buffer != null && buffer.length < current + 1) {
			cbuffer = null;
			buffer = null;
			start = 0;
			end = 0;
			current = 0;
			return false;
		}
		while (cbuffer == null || buffer.length==0) {
			cbuffer = new StringBuffer();
			int c = 0;
			while ((c = input.read()) != -1) {
				cbuffer.append((char) c);
			}
			buffer = CNLPIRLibrary.Instance.NLPIR_ParagraphProcess(cbuffer.toString(), 0).split("\\s");
		}
		clearAttributes();
		int length = buffer[current].length();
		end = start + length;
		termAtt.copyBuffer(buffer[current].toCharArray(), 0, length);
		offsetAtt.setOffset(correctOffset(start), correctOffset(end));
		typeAtt.setType("word");
		start = end;
		current += 1;
		return true;
	}

}
