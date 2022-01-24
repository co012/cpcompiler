[#--
/* Copyright (c) 2008-2021 Jonathan Revusky, revusky@javacc.com
 * All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions are met:
 *
 *     * Redistributions of source code must retain the above copyright notices,
 *       this list of conditions and the following disclaimer.
 *     * Redistributions in binary form must reproduce the above copyright
 *       notice, this list of conditions and the following disclaimer in the
 *       documentation and/or other materials provided with the distribution.
 *     * Neither the name Jonathan Revusky, Sun Microsystems, Inc.
 *       nor the names of any contributors may be used to endorse
 *       or promote products derived from this software without specific prior written
 *       permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
 * AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
 * IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
 * ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE
 * LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
 * CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
 * SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
 * INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
 * CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
 * ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF
 * THE POSSIBILITY OF SUCH DAMAGE.
 */
 --]
 /* Generated by: ${generated_by}. ${filename} */
 
 [#--
    This template generates the XXXLexer.java class.
    The details of generating the code for the NFA state machine
    are in the imported template NfaCode.java.ftl
 --]
 
[#if grammar.parserPackage?has_content]
    package ${grammar.parserPackage};
    import static ${grammar.parserPackage}.${grammar.constantsClassName}.TokenType.*;
[/#if]

[#import "CommonUtils.java.ftl" as CU  ]

[#var lexerData=grammar.lexerData]
[#var multipleLexicalStates = lexerData.lexicalStates.size()>1]

[#var PRESERVE_LINE_ENDINGS=grammar.preserveLineEndings?string("true", "false")
      JAVA_UNICODE_ESCAPE= grammar.javaUnicodeEscape?string("true", "false")
      ENSURE_FINAL_EOL = grammar.ensureFinalEOL?string("true", "false")]

[#macro EnumSet varName tokenNames]
   [#if tokenNames?size=0]
       static private final EnumSet<TokenType> ${varName} = EnumSet.noneOf(TokenType.class);
   [#else]
       static final EnumSet<TokenType> ${varName} = EnumSet.of(
       [#list tokenNames as type]
          [#if type_index > 0],[/#if]
          ${CU.TT}${type} 
       [/#list]
     ); 
   [/#if]
[/#macro]

[#list grammar.parserCodeImports as import]
   ${import}
[/#list]

import java.io.*;
import java.util.Arrays;
import java.util.BitSet;
import java.util.EnumMap;
import java.util.EnumSet;

public class ${grammar.lexerClassName} implements ${grammar.constantsClassName} {

  final Token DUMMY_START_TOKEN = new Token();
// Just a dummy Token value that we put in the tokenLocationTable
// to indicate that this location in the file is ignored.
  static final private Token IGNORED = new Token();

   // Munged content, possibly replace unicode escapes, tabs, or CRLF with LF.
    private CharSequence content;
    // Typically a filename, I suppose.
    private String inputSource = "input";
    // A list of offsets of the beginning of lines
    private int[] lineOffsets;

    // The starting line and column, usually 1,1
    // that is used to report a file position 
    // in 1-based line/column terms
    private int startingLine, startingColumn;

    // The offset in the internal buffer to the very
    // next character that the readChar method returns
    private int bufferPosition;


// A BitSet that stores where the tokens are located.
// This is not strictly necessary, I suppose...
    private BitSet tokenOffsets;

// Just a very simple, bloody minded approach, just store the
// Token objects in a table where the offsets are the code unit 
// positions in the content buffer. If the Token at a given offset is
// the dummy or marker type IGNORED, then the location is skipped via
// whatever preprocessor logic.    
    private Token[] tokenLocationTable;


 [#if grammar.lexerUsesParser]
  public ${grammar.parserClassName} parser;
 [/#if]
  // The following two BitSets are used to store 
  // the current active NFA states in the core tokenization loop
  private BitSet nextStates=new BitSet(${lexerData.maxNfaStates}), currentStates = new BitSet(${lexerData.maxNfaStates});

  EnumSet<TokenType> activeTokenTypes = EnumSet.allOf(TokenType.class);
  [#if grammar.deactivatedTokens?size>0 || grammar.extraTokens?size >0]
     {
       [#list grammar.deactivatedTokens as token]
          activeTokenTypes.remove(${CU.TT}${token});
       [/#list]
       [#list grammar.extraTokenNames as token]
          regularTokens.add(${CU.TT}${token});
       [/#list]
     }
  [/#if]

[#if lexerData.hasLexicalStateTransitions]
  // A lookup for lexical state transitions triggered by a certain token type
  private static EnumMap<TokenType, LexicalState> tokenTypeToLexicalStateMap = new EnumMap<>(TokenType.class);
[/#if]
  // Token types that are "regular" tokens that participate in parsing,
  // i.e. declared as TOKEN
  [@EnumSet "regularTokens" lexerData.regularTokens.tokenNames /]
  // Token types that do not participate in parsing, a.k.a. "special" tokens in legacy JavaCC,
  // i.e. declared as UNPARSED (or SPECIAL_TOKEN)
  [@EnumSet "unparsedTokens" lexerData.unparsedTokens.tokenNames /]
  [#-- // Tokens that are skipped, i.e. SKIP
  N.B. This concept is being eliminated!
  [@EnumSet "skippedTokens" lexerData.skippedTokens.tokenNames / --]
  // Tokens that correspond to a MORE, i.e. that are pending 
  // additional input
  [@EnumSet "moreTokens" lexerData.moreTokens.tokenNames /]

  private InvalidToken invalidToken;
  // The source of the raw characters that we are scanning  

  public String getInputSource() {
      return inputSource;
  }
  
  public void setInputSource(String inputSource) {
      this.inputSource = inputSource;
  }
   
  public ${grammar.lexerClassName}(CharSequence input) {
    this("input", input);
  }


     /**
      * @param inputSource just the naem of the input source (typically the filename)
      * that will be used in error messages and so on.
      * @param input the input
      */
     public ${grammar.lexerClassName}(String inputSource, CharSequence input) {
        this(inputSource, input, LexicalState.${lexerData.lexicalStates[0].name}, 1, 1);
     }

     /**
      * @param inputSource just the name of the input source (typically the filename) that 
      * will be used in error messages and so on.
      * @param input the input
      * @param line The line number at which we are starting for the purposes of location/error messages. In most 
      * normal usage, this is 1.
      * @param column number at which we are starting for the purposes of location/error messages. In most normal
      * usages this is 1.
      */
     public ${grammar.lexerClassName}(String inputSource, CharSequence input, LexicalState lexState, int startingLine, int startingColumn) {
        this.inputSource = inputSource;
        this.content = mungeContent(input, ${grammar.tabsToSpaces}, ${PRESERVE_LINE_ENDINGS}, ${JAVA_UNICODE_ESCAPE}, ${ENSURE_FINAL_EOL});
        this.inputSource = inputSource;
        this.lineOffsets = createLineOffsetsTable(this.content);
        tokenLocationTable = new Token[content.length()+1];
        tokenOffsets = new BitSet(content.length() +1);
        this.startingLine = startingLine;
        this.startingColumn = startingColumn;
        switchTo(lexState);
     }

    /**
     * @Deprecated Preferably use the constructor that takes a #java.nio.files.Path or simply a String,
     * depending on your use case
     */
    public ${grammar.lexerClassName}(Reader reader) {
       this("input", reader, LexicalState.${lexerData.lexicalStates[0].name}, 1, 1);
    }
    /**
     * @Deprecated Preferably use the constructor that takes a #java.nio.files.Path or simply a String,
     * depending on your use case
     */
    public ${grammar.lexerClassName}(String inputSource, Reader reader) {
       this(inputSource, reader, LexicalState.${lexerData.lexicalStates[0].name}, 1, 1);
    }

    /**
     * @Deprecated Preferably use the constructor that takes a #java.nio.files.Path or simply a String,
     * depending on your use case
     */
    public ${grammar.lexerClassName}(String inputSource, Reader reader, LexicalState lexState, int line, int column) {
        this(inputSource, ${grammar.constantsClassName}.readToEnd(reader), lexState, line, column);
        switchTo(lexState);
    }

    private Token getNextToken() {
      Token token = null;
      do {
          token = nextToken();
      } while (token instanceof InvalidToken);
      if (invalidToken != null) {
          invalidToken.setTokenSource(this);
          Token it = invalidToken;
          this.invalidToken = null;
[#if grammar.faultTolerant]
          it.setUnparsed(true);
[/#if]
          cacheToken(it);
          return it;
      }
      cacheToken(token);
      return token;
    }

  /**
   * The public method for getting the next token.
   * If the tok parameter is null, it just tokenizes 
   * starting at the internal bufferPosition
   * Otherwise, it checks whether we have already cached
   * the token after this one. If not, it finally goes 
   * to the NFA machinery
   */ 
    public Token getNextToken(Token tok) {
       if(tok == null) {
           return getNextToken();
       }
       Token cachedToken = tok.nextCachedToken();
    // If the cached next token is not currently active, we
    // throw it away and go back to the XXXLexer
       if (cachedToken != null && !activeTokenTypes.contains(cachedToken.getType())) {
           reset(tok);
           cachedToken = null;
       }
       return cachedToken != null ? cachedToken : getNextToken(tok.getEndOffset());
    }

    /**
     * A lower level method to tokenize, that takes the absolute
     * offset into the content buffer as a parameter
     * @param offset where to start
     * @return the token that results from scanning from the given starting point 
     */
    public Token getNextToken(int offset) {
        goTo(offset);
        return getNextToken();
    }

// The main method to invoke the NFA machinery
 private final Token nextToken() {
      Token matchedToken = null;
      boolean inMore = false;
      int tokenBeginOffset = this.bufferPosition, firstChar =0;
      // The core tokenization loop
      while (matchedToken == null) {
        int curChar, codeUnitsRead=0, matchedPos=0;
        TokenType matchedType = null;
        boolean reachedEnd = false;
        if (inMore) {
            curChar = readChar();
            if (curChar == -1) reachedEnd = true;
        }
        else {
            tokenBeginOffset = this.bufferPosition;
            firstChar = curChar = readChar();
            if (curChar == -1) {
              matchedType = TokenType.EOF;
              reachedEnd = true;
            }
        } 
      [#if multipleLexicalStates]
       // Get the NFA function table current lexical state
       // There is some possibility that there was a lexical state change
       // since the last iteration of this loop!
      [/#if]
        ${grammar.nfaDataClassName}.NfaFunction[] nfaFunctions= ${grammar.nfaDataClassName}.getFunctionTableMap(lexicalState);
        // the core NFA loop
        if (!reachedEnd) do {
            // Holder for the new type (if any) matched on this iteration
            TokenType newType = null;
            if (codeUnitsRead > 0) {
                // What was nextStates on the last iteration 
                // is now the currentStates!
                BitSet temp = currentStates;
                currentStates = nextStates;
                nextStates = temp;
                int retval = readChar();
                if (retval >=0) {
                    curChar = retval;
                }
                else {
                    reachedEnd = true;
                    break;
                }
            }
            nextStates.clear();
            if (codeUnitsRead == 0) {
                TokenType returnedType = nfaFunctions[0].apply(curChar, nextStates, activeTokenTypes);
                if (returnedType != null && (newType == null || returnedType.ordinal() < newType.ordinal())) {
                  newType = returnedType;
                } 
            } else {
                int nextActive = currentStates.nextSetBit(0);
                while (nextActive != -1) {
                    TokenType returnedType = nfaFunctions[nextActive].apply(curChar, nextStates, activeTokenTypes);
                    if (returnedType != null && (newType == null || returnedType.ordinal() < newType.ordinal())) {
                      newType = returnedType;
                    }
                    nextActive = currentStates.nextSetBit(nextActive+1);
                } 
            }
            ++codeUnitsRead;
            if (curChar>0xFFFF) ++codeUnitsRead;
            if (newType != null) {
                matchedType = newType;
                inMore = moreTokens.contains(matchedType);
                matchedPos= codeUnitsRead;
            }
        } while (!nextStates.isEmpty());
        if (matchedType == null) {
            bufferPosition = tokenBeginOffset+1;
            if (firstChar>0xFFFF) ++bufferPosition;
            return new InvalidToken(this, tokenBeginOffset, bufferPosition);
        } 
        bufferPosition -= (codeUnitsRead - matchedPos);
        if (regularTokens.contains(matchedType) || unparsedTokens.contains(matchedType)) {
            matchedToken = Token.newToken(matchedType, 
                                        this, 
                                        tokenBeginOffset,
                                        bufferPosition);
            matchedToken.setUnparsed(!regularTokens.contains(matchedType));
 [#list grammar.lexerTokenHooks as tokenHookMethodName]
    [#if tokenHookMethodName = "CommonTokenAction"]
           ${tokenHookMethodName}(matchedToken);
    [#else]
            matchedToken = ${tokenHookMethodName}(matchedToken);
    [/#if]
 [/#list]
        }
     [#if lexerData.hasTokenActions]
        matchedToken = tokenLexicalActions(matchedToken, matchedType);
     [/#if]
     [#if multipleLexicalStates]
        doLexicalStateSwitch(matchedType);
     [/#if]
      }
      return matchedToken;
   }

   LexicalState lexicalState = LexicalState.values()[0];
[#if multipleLexicalStates]
  boolean doLexicalStateSwitch(TokenType tokenType) {
       LexicalState newState = tokenTypeToLexicalStateMap.get(tokenType);
       if (newState == null) return false;
       return switchTo(newState);
  }
[/#if]
  
    /** 
     * Switch to specified lexical state. 
     * @param  private final Token nextToken() {
lexState the lexical state to switch to
     * @return whether we switched (i.e. we weren't already in the desired lexical state)
     */
    public boolean switchTo(LexicalState lexState) {
        if (this.lexicalState != lexState) {
           this.lexicalState = lexState;
           return true;
        }
        return false;
    }

    // Reset the token source input
    // to just after the Token passed in.
    void reset(Token t, LexicalState state) {
[#list grammar.resetTokenHooks as resetTokenHookMethodName]
      ${resetTokenHookMethodName}(t);
[/#list]
      goTo(t.getEndOffset());
      uncacheTokens(t);
      if (state != null) {
          switchTo(state);
      }
[#if multipleLexicalStates] 
        else {
          doLexicalStateSwitch(t.getType());
        }
[/#if]        
    }

  void reset(Token t) {
      reset(t, null);
  }
    
 [#if lexerData.hasTokenActions]
  private Token tokenLexicalActions(Token matchedToken, TokenType matchedType) {
    switch(matchedType) {
   [#list lexerData.regularExpressions as regexp]
        [#if regexp.codeSnippet?has_content]
		  case ${regexp.label} :
		      ${regexp.codeSnippet.javaCode}
           break;
        [/#if]
   [/#list]
      default : break;
    }
    return matchedToken;
  }
 [/#if]

 [#if lexerData.hasLexicalStateTransitions]
  // Generate the map for lexical state transitions from the various token types
  static {
    [#list grammar.lexerData.regularExpressions as regexp]
      [#if !regexp.newLexicalState?is_null]
          tokenTypeToLexicalStateMap.put(TokenType.${regexp.label},LexicalState.${regexp.newLexicalState.name});
      [/#if]
    [/#list]
  }
 [/#if]

    /**
     * The offset of the end of the given line. This is in code units.
     */
    private int getLineEndOffset(int lineNumber) {
        int realLineNumber = lineNumber - startingLine;
        if (realLineNumber <0) {
            return 0;
        }
        if (realLineNumber >= lineOffsets.length) {
            return content.length();
        }
        if (realLineNumber == lineOffsets.length -1) {
            return content.length() -1;
        }
        return lineOffsets[realLineNumber+1] -1;
    }

    // But there is no goto in Java!!!
    private void goTo(int offset) {
        while (tokenLocationTable[offset] == IGNORED && offset < content.length()) {
            ++offset;
        }
        this.bufferPosition = offset;
    }

    /**
     * @return the line length in code _units_
     */ 
    private int getLineLength(int lineNumber) {
        int startOffset = getLineStartOffset(lineNumber);
        int endOffset = getLineEndOffset(lineNumber);
        return 1+endOffset - startOffset;
    }

    /**
     * The number of supplementary unicode characters in the specified 
     * offset range. The range is expressed in code units
     */
    private int numSupplementaryCharactersInRange(int start, int end) {
        int result =0;
        while (start < end-1) {
            if (Character.isHighSurrogate(content.charAt(start++))) {
                if (Character.isLowSurrogate(content.charAt(start))) {
                    start++;
                    result++;
                }
            }
        }
        return result;
    }

    /**
     * The offset of the start of the given line. This is in code units
     */
    private int getLineStartOffset(int lineNumber) {
        int realLineNumber = lineNumber - startingLine;
        if (realLineNumber <=0) {
            return 0;
        }
        if (realLineNumber >= lineOffsets.length) {
            return content.length();
        }
        return lineOffsets[realLineNumber];
    }

    private int readChar() {
        while (tokenLocationTable[bufferPosition] == IGNORED && bufferPosition < content.length()) {
            ++bufferPosition;
        }
        if (bufferPosition >= content.length()) {
            return -1;
        }
        char ch = content.charAt(bufferPosition++);
        if (Character.isHighSurrogate(ch) && bufferPosition < content.length()) {
            char nextChar = content.charAt(bufferPosition);
            if (Character.isLowSurrogate(nextChar)) {
                ++bufferPosition;
                return Character.toCodePoint(ch, nextChar);
            }
        }
        return ch;
    }

    /**
     * This is used in conjunction with having a preprocessor.
     * We set which lines are actually parsed lines and the 
     * unset ones are ignored. 
     * @param parsedLines a #java.util.BitSet that holds which lines
     * are parsed (i.e. not ignored)
     */
    public void setParsedLines(BitSet parsedLines) {
        for (int i=0; i < lineOffsets.length; i++) {
            if (!parsedLines.get(i+1)) {
                int lineOffset = lineOffsets[i];
                int nextLineOffset = i < lineOffsets.length -1 ? lineOffsets[i+1] : content.length();
                for (int offset = lineOffset; offset < nextLineOffset; offset++) {
                    tokenLocationTable[offset] = IGNORED;
                }
            }
        }
    }

    /**
     * @return the line number from the absolute offset passed in as a parameter
     */
    int getLineFromOffset(int pos) {
        if (pos >= content.length()) {
            if (content.charAt(content.length()-1) == '\n') {
                return startingLine + lineOffsets.length;
            }
            return startingLine + lineOffsets.length-1;
        }
        int bsearchResult = Arrays.binarySearch(lineOffsets, pos);
        if (bsearchResult>=0) {
            return startingLine + bsearchResult;
        }
        return startingLine-(bsearchResult+2);
    }

    int getCodePointColumnFromOffset(int pos) {
        if (pos >= content.length()) return 1;
        if (pos == 0) return startingColumn;
        if (Character.isLowSurrogate(content.charAt(pos))) --pos;
        int line = getLineFromOffset(pos)-startingLine;
        int lineStart = lineOffsets[line];
        int numSupps = numSupplementaryCharactersInRange(lineStart, pos);
        int startColumnAdjustment = line > 0 ? 1 : startingColumn;
        return startColumnAdjustment+pos-lineOffsets[line]-numSupps;
    }
    
    /**
     * @return the text between startOffset (inclusive)
     * and endOffset(exclusive)
     */
    String getText(int startOffset, int endOffset) {
        StringBuilder buf = new StringBuilder();
        for (int offset = startOffset; offset < endOffset; offset++) {
            if (tokenLocationTable[offset] != IGNORED) {
                buf.append(content.charAt(offset));
            }
        }
        return buf.toString();
    }

    void cacheToken(Token tok) {
[#if !grammar.minimalToken]        
        if (tok.isInserted()) {
            Token next = tok.nextCachedToken();
            if (next != null) cacheToken(next);
            return;
        }
[/#if]        
	    int offset = tok.getBeginOffset();
	    tokenOffsets.set(offset);
	    tokenLocationTable[offset] = tok;
    }

    void uncacheTokens(Token lastToken) {
        int endOffset = lastToken.getEndOffset();
        if (endOffset < tokenOffsets.length()) {
            tokenOffsets.clear(lastToken.getEndOffset(), tokenOffsets.length());
        }
      [#if !grammar.minimalToken]
        lastToken.unsetAppendedToken();
      [/#if]
    }

    Token nextCachedToken(int offset) {
      int nextOffset = tokenOffsets.nextSetBit(offset);
	    return nextOffset != -1 ? tokenLocationTable[nextOffset] : null;
    } 

    Token previousCachedToken(int offset) {
        int prevOffset = tokenOffsets.previousSetBit(offset-1);
        return prevOffset == -1 ? null : tokenLocationTable[prevOffset];
    }

    /**
     * Given the line number and the column in code points,
     * returns the column in code units.
     */
    private static int[] createLineOffsetsTable(CharSequence content) {
        if (content.length() == 0) {
            return new int[0];
        }
        int lineCount = 0;
        int length = content.length();
        for (int i = 0; i < length; i++) {
            char ch = content.charAt(i);
            if (ch == '\n') {
                lineCount++;
            }
        }
        if (content.charAt(length - 1) != '\n') {
            lineCount++;
        }
        int[] lineOffsets = new int[lineCount];
        lineOffsets[0] = 0;
        int index = 1;
        for (int i = 0; i < length; i++) {
            char ch = content.charAt(i);
            if (ch == '\n') {
                if (i + 1 == length)
                    break;
                lineOffsets[index++] = i + 1;
            }
        }
        return lineOffsets;
    }
 
// Icky method to handle annoying stuff. Might make this public later if it is
// needed elsewhere
  private static String mungeContent(CharSequence content, int tabsToSpaces, boolean preserveLines,
        boolean javaUnicodeEscape, boolean ensureFinalEndline) {
    if (tabsToSpaces <= 0 && preserveLines && !javaUnicodeEscape) {
        if (ensureFinalEndline) {
            if (content.length() == 0) {
                content = "\n";
            } else {
                int lastChar = content.charAt(content.length()-1);
                if (lastChar != '\n' && lastChar != '\r') {
                    if (content instanceof StringBuilder) {
                        ((StringBuilder) content).append((char) '\n');
                    } else {
                        StringBuilder buf = new StringBuilder(content);
                        buf.append((char) '\n');
                        content = buf.toString();
                    }
                }
            }
        }
        return content.toString();
    }
    StringBuilder buf = new StringBuilder();
    // This is just to handle tabs to spaces. If you don't have that setting set, it
    // is really unused.
    int col = 0;
    int index = 0, contentLength = content.length();
    while (index < contentLength) {
        char ch = content.charAt(index++);
        if (ch == '\n') {
            buf.append(ch);
            col=0;
        }
        else if (javaUnicodeEscape && ch == '\\' && index<contentLength && content.charAt(index)=='u') {
            int numPrecedingSlashes = 0;
            for (int i = index-1; i>=0; i--) {
                if (content.charAt(i) == '\\') 
                    numPrecedingSlashes++;
                else break;
            }
            if (numPrecedingSlashes % 2 == 0) {
                buf.append((char) '\\');
                continue;
            }
            int numConsecutiveUs = 0;
            for (int i = index; i<contentLength; i++) {
                if (content.charAt(i) == 'u') numConsecutiveUs++;
                else break;
            }
            String fourHexDigits = content.subSequence(index+numConsecutiveUs, index+numConsecutiveUs+4).toString();
            buf.append((char) Integer.parseInt(fourHexDigits, 16));
            index+=(numConsecutiveUs +4);
        }
        else if (!preserveLines && ch == '\r') {
            buf.append((char)'\n');
            col = 0;
            if (index < contentLength && content.charAt(index) == '\n') {
                ++index;
            }
        } else if (ch == '\t' && tabsToSpaces > 0) {
            int spacesToAdd = tabsToSpaces - col % tabsToSpaces;
            for (int i = 0; i < spacesToAdd; i++) {
                buf.append((char) ' ');
                col++;
            }
        } else {
            buf.append(ch);
            if (!Character.isLowSurrogate(ch)) col++;
        }
    }
    if (ensureFinalEndline) {
        if (buf.length() ==0) {
            return "\n";
        }
        char lastChar = buf.charAt(buf.length()-1);
        if (lastChar != '\n' && lastChar!='\r') buf.append((char) '\n');
    }
    return buf.toString();
  }
}
