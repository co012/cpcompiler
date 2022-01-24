[#ftl strict_vars=true]
[#--
/* Copyright (c) 2008-2019 Jonathan Revusky, revusky@javacc.com
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
[#if grammar.parserPackage?has_content]
package ${grammar.parserPackage};
[/#if]
import java.util.ArrayList;
import java.util.Collections;
import java.util.HashMap;
import java.util.Iterator;
import java.util.List;
import java.util.ListIterator;
import java.lang.reflect.*;
import java.util.function.Predicate;
[#if grammar.settings.FREEMARKER_NODES?? && grammar.settings.FREEMARKER_NODES]
import freemarker.template.*;
[/#if]

public interface Node extends Comparable<Node> 
[#if grammar.settings.FREEMARKER_NODES?? && grammar.settings.FREEMARKER_NODES]
   , TemplateNodeModel, TemplateScalarModel
[/#if] {

    /** Life-cycle hook method called after the node has been made the current
	 *  node 
	 */
    default void open() {}

  	/** 
  	 * Life-cycle hook method called after all the child nodes have been
     * added. 
     */
    default void close() {}


    /**
     * @return the input source (usually a filename) from which this Node came from
     */
    default String getInputSource() {
        ${grammar.lexerClassName} tokenSource = getTokenSource();
        return tokenSource == null ? "input" : tokenSource.getInputSource();
    }

   /**
     * Returns whether this node has any children.
     * 
     * @return Returns <code>true</code> if this node has any children,
     *         <code>false</code> otherwise.
     */
    default boolean hasChildNodes() {
       return getChildCount() > 0;
    }

    /**
     * @param n The Node to set as the parent. Mostly used internally.
     * The various addChild or appendChild sorts of methods should use this 
     * to set the node's parent. 
     */
    void setParent(Node n);

    /**
     * @return this node's parent Node 
     */
    Node getParent();
     
     // The following 9 methods will typically just 
     // delegate straightforwardly to a List object that
     // holds the child nodes

     /**
      * appends a child node to this Node
      * @param n the Node to append
      */ 
     void addChild(Node n);

     /**
      * inserts a child Node at a specific index, displacing the 
      * nodes after the index by 1.
      * @param i the (zero-based) index at which to insert the node
      * @param n the Node to insert
      */
     void addChild(int i, Node n);

     /**
      * @return the Node at the specific offset
      * @param i the index of the Node to return
      */
     Node getChild(int i);

     /**
      * Replace the node at index i
      * @param i the index
      * @param n the node  
      */ 
     void setChild(int i, Node n);

     /**
      * Remove the node at index i. Any Nodes after i
      * are shifted to the left.
      * @return the removed Node
      * @param i the index at which to remove 
      */
     Node removeChild(int i);

     /**
      * Removes the Node from this node's children
      * @param n the Node to remove
      * @return whether the Node was present
      */ 
     default boolean removeChild(Node n) {
         int index = indexOf(n);
         if (index == -1) return false;
         removeChild(index);
         return true;
     }

     /**
      * Replaces a child node with another one. It does
      * nothing if the first parameter is not actually a child node.
      * @param current the Node to be replaced
      * @param replacement the Node to substitute
      * @return whether any replacement took place
      */
     default boolean replaceChild(Node current, Node replacement) {
         int index = indexOf(current);
         if (index == -1) return false;
         setChild(index, replacement);
         return true;
     }

     /**
      * Insert a Node right before a given Node. It does nothing
      * if the where Node is not actually a child node.
      * @param where the Node that is the location where to prepend
      * @param inserted the Node to prepend
      * @return whether a Node was prepended 
      */
     default boolean prependChild(Node where, Node inserted) {
         int index = indexOf(where);
         if (index == -1) return false;
         addChild(index, inserted);
         return true;
     }

     /**
      * Insert a node right after a given Node. It does nothing 
      * if the where node is not actually a child node.
      * @param where the Node after which to append
      * @param inserted the Node to be inserted
      * @return whether a Node really was appended
      */
     default boolean appendChild(Node where, Node inserted) {
         int index = indexOf(where);
         if (index == -1) return false;
         addChild(index+1, inserted);
         return true;
     }

     /**
      * @return the index of the child Node. Or -1 if it is not
      * a child Node.
      * @param child the Node to get the index of
      */
     default int indexOf(Node child) {
         for (int i=0; i<getChildCount(); i++) {
             if (child == getChild(i)) {
                 return i;
             }
         }
         return -1;
     }

     /**
      * Used to order Nodes by location.
      * @param n the Node to compare to
      * @return typical Comparator semantics
      */
     default int compareTo(Node n) {
         if (this == n) return 0;
         int diff = this.getBeginLine() - n.getBeginLine();
         if (diff !=0) return diff;
         diff = this.getBeginColumn() -n.getBeginColumn();
         if (diff != 0) return diff;
         // A child node is considered to come after its parent.
         diff = n.getEndLine() - this.getEndLine();
         if (diff != 0) return diff;
         return n.getEndColumn() - this.getEndColumn();
     }

     /**
      * Remove all the child nodes
      */
     void clearChildren();

     /**
      * @return the number of child nodes
      */
     int getChildCount();
     
     /**
      * @return a List containing this node's child nodes
      * The default implementation returns a copy, so modifying the 
      * list that is returned has no effect on this object. Most 
      * implementations of this should similarly return a copy or
      * possibly immutable wrapper around the list.
      */
      default List<Node> children() {
         List<Node> result = new ArrayList<>();
         for (int i = 0; i < getChildCount(); i++) {
             result.add(getChild(i));
         }
         return result;
      }

    /**
     * @return a List containing all the tokens in a Node
     * @param includeCommentTokens Whether to include comment tokens
     */
     default List<Token> getAllTokens(boolean includeCommentTokens) {
		List<Token> result = new ArrayList<Token>();
        for (Iterator<Node> it = iterator(); it.hasNext();) {
            Node child = it.next();
            if (child instanceof Token) {
                Token token = (Token) child;
                if (token.isUnparsed()) {
                    continue;
                }
                if (includeCommentTokens) {
                    ArrayList<Token> comments = null;
                    Token prev = token.previousCachedToken();
                    while (prev != null && prev.isUnparsed()) {
                        if (comments == null) comments = new ArrayList<>();
                        comments.add(prev);
                        prev = prev.previousCachedToken();
                    }
                    if (comments !=null) {
                        Collections.reverse(comments);
                        result.addAll(comments);
                    }
                }
                result.add(token);
            } 
            else if (child.getChildCount() >0) {
               result.addAll(child.getAllTokens(includeCommentTokens));
            }
        }
        return result;
    }

    /**
     * @return All the tokens in the node that 
     * are "real" (i.e. participate in parsing)
     */
    default List<Token> getRealTokens() {
        return descendants(Token.class, t->!t.isUnparsed());
    }
    
     /**
      * @return the #${grammar.lexerClassName} from which this Node object
      * originated. There is no guarantee that this doesn't return null.
      * Most likely that would simply be because you constructed the 
      * Node yourself, i.e. it didn't really come about via the parsing/tokenizing
      * machinery.
      */
     ${grammar.lexerClassName} getTokenSource();

     void setTokenSource(${grammar.lexerClassName} tokenSource);

     /**
      * @return the original source content this Node came from
      * a reference to the #${grammar.lexerClassName} that stores the source code and
      * the start/end location info stored in the Node object itself.
      * This method could throw a NullPointerException if #getTokenSource
      * returns null. Also, the return value could be spurious if 
      * the content of the source file was changed meanwhile. But
      * this is just the default implementation of an API and it does not 
      * address this problem!
      */
     default String getSource() {
        ${grammar.lexerClassName} tokenSource = getTokenSource();
        return tokenSource == null ? null : tokenSource.getText(getBeginOffset(), getEndOffset());
    }

    /**
     * @return the (1-based) line location where this Node starts
     */      
    default int getBeginLine() {
        ${grammar.lexerClassName} tokenSource = getTokenSource();
        return tokenSource == null ? 0 : tokenSource.getLineFromOffset(getBeginOffset());                
    };

    /**
     * @return the (1-based) line location where this Node ends
     */
    default int getEndLine() {
        ${grammar.lexerClassName} tokenSource = getTokenSource();
        return tokenSource == null ? 0 : tokenSource.getLineFromOffset(getEndOffset()-1);
    };

    /**
     * @return the (1-based) column where this Node starts
     */
    default int getBeginColumn() {
        ${grammar.lexerClassName} tokenSource = getTokenSource();
        return tokenSource == null ? 0 : tokenSource.getCodePointColumnFromOffset(getBeginOffset());        
    };

    /**
     * @return the (1-based) column offset where this Node ends
     */ 
    default int getEndColumn() {
        ${grammar.lexerClassName} tokenSource = getTokenSource();
        return tokenSource == null ? 0 : tokenSource.getCodePointColumnFromOffset(getEndOffset()-1);
    }
    
    /**
     * @return the offset in the input source where the token begins,
     * expressed in code units.
     */
    int getBeginOffset();

    /**
     * @return the offset in the input source where the token ends,
     * expressed in code units. This is actually the offset where the 
     * very next token would begin.
     */
     int getEndOffset();

     /**
      * Set the offset where the token begins, expressed in code units. 
      */
      void setBeginOffset(int beginOffset);

     /**
      * Set the offset where the token ends, actually the location where
      * the very next token should begin.
      */
      void setEndOffset(int endOffet);

    /**
     * @return a String that gives the starting location of this Node. This is a default
     * implementation that could be overridden 
     */
    default String getLocation() {
         return getInputSource() + ":" + getBeginLine() + ":" + getBeginColumn();
    }
     
     
     /**
      * @return whether this Node was created by regular operations of the 
      * parsing machinery. 
      */
     default boolean isUnparsed() {
        return false;
     }

     /**
      * Mark whether this Node is unparsed, i.e. <i>not</i> the result of 
      * normal parsing
      * @param b whether to set the Node as unparsed or parsed.
      */ 
     void setUnparsed(boolean b);
     
    default <T extends Node>T firstChildOfType(Class<T>clazz) {
        for (int i=0; i<getChildCount();i++) {
            Node child = getChild(i);
            if (clazz.isInstance(child)) return clazz.cast(child);
        }
        return null; 
    }

    default <T extends Node>T firstChildOfType(Class<T> clazz, Predicate<T> pred) {
        for (int i=0; i<getChildCount();i++) {
            Node child = getChild(i);
            if (clazz.isInstance(child)) {
                T t = clazz.cast(child);
                if (pred.test(t)) return t;
            }
        }
        return null;
    }

[#if grammar.tokensAreNodes]
    default Token firstDescendantOfType(${grammar.constantsClassName}.TokenType type) {
         for (int i=0; i<getChildCount(); i++) {
             Node child = getChild(i);
             if (child instanceof Token) {
                 Token tok = (Token) child;
                 if (tok.getType()==type) {
                     return tok;
                 }
             } else {
                 Token tok = child.firstDescendantOfType(type);
                 if (tok != null) return tok;
             }
         }
         return null;
    }

    default Token firstChildOfType(${grammar.constantsClassName}.TokenType tokenType) {
        for (int i=0; i<getChildCount();i++) {
            Node child = getChild(i);
            if (child instanceof Token) {
                Token tok = (Token) child;
                if (tok.getType() == tokenType) return tok;
            }
        }
        return null;
    }
[/#if]

    default <T extends Node>T firstDescendantOfType(Class<T> clazz) {
         for (int i=0; i<getChildCount();i++) {
             Node child = getChild(i);
             if (clazz.isInstance(child)) return clazz.cast(child);
             else {
                 T descendant = child.firstDescendantOfType(clazz);
                 if (descendant !=null) return descendant;
             }
         }
         return null;
    }

    default <T extends Node>List<T>childrenOfType(Class<T>clazz) {
        List<T>result=new java.util.ArrayList<>();
        for (int i=0; i< getChildCount(); i++) {
            Node child = getChild(i);
            if (clazz.isInstance(child)) {
                result.add(clazz.cast(child));
            }
        }
        return result;
   }
   
   default <T extends Node> List<T> descendantsOfType(Class<T> clazz) {
        List<T> result = new ArrayList<T>();
        for (int i=0; i< getChildCount(); i++) {
            Node child = getChild(i);
            if (clazz.isInstance(child)) {
                result.add(clazz.cast(child));
            } 
            result.addAll(child.descendantsOfType(clazz));
        }
        return result;
   }
   
   default <T extends Node> T firstAncestorOfType(Class<T> clazz) {
        Node parent = this;
        while (parent !=null) {
           parent = parent.getParent();
           if (clazz.isInstance(parent)) {
               return clazz.cast(parent);
           }
        }
        return null;
    }

    default ${grammar.constantsClassName}.TokenType getTokenType() {
        return this instanceof Token ? ((Token)this).getType() : null;
    }

[#if grammar.tokensAreNodes]
    /**
     * @return the very first token that is part of this node.
     * It may be an unparsed (i.e. special) token.
     */
    default Token getFirstToken() {
        Node first = getFirstChild();
        if (first == null) return null;
        if (first instanceof Token) {
            Token tok = (Token) first;
            while (tok.previousCachedToken() != null && tok.previousCachedToken().isUnparsed()) {
                tok = tok.previousCachedToken();
            }
           return tok;
        }
        return first.getFirstToken(); 
    }

    default Token getLastToken() {
        Node last = getLastChild();
        if (last == null) return null;
        if (last instanceof Token) {
            return (Token) last;
        }
        return last.getLastToken();
    }
[/#if]    
    
    /**
     * Copy the location info from another Node
     * @param from the Node to copy the info from 
     */
    default void copyLocationInfo(Node from) {
        setTokenSource(from.getTokenSource());
        setBeginOffset(from.getBeginOffset());
        setEndOffset(from.getEndOffset());
        setTokenSource(from.getTokenSource());
    }

    /**
     * Copy the location info given a start and end Node
     * @param start the start node
     * @param end the end node
     */
    default void copyLocationInfo(Node start, Node end) {
        setTokenSource(start.getTokenSource());
        if (getTokenSource()==null) setTokenSource(end.getTokenSource());
        setBeginOffset(start.getBeginOffset());
        setEndOffset(end.getEndOffset());
    }

    default void replace(Node toBeReplaced) {
        copyLocationInfo(toBeReplaced);
        Node parent = toBeReplaced.getParent();
        if (parent !=null) {
           int index = parent.indexOf(toBeReplaced);
           parent.setChild(index, this);
        }
    }
    
    /**
     * Returns the first child of this node. If there is no such node, this returns
     * <code>null</code>.
     * 
     * @return the first child of this node. If there is no such node, this returns
     *         <code>null</code>.
     */
    default Node getFirstChild() {
        return getChildCount() > 0 ? getChild(0) : null;
    }
    
    
     /**
     * Returns the last child of the given node. If there is no such node, this
     * returns <code>null</code>.
     * 
     * @return the last child of the given node. If there is no such node, this
     *         returns <code>null</code>.
     */ 
    default Node getLastChild() {
        int count = getChildCount();
        return count>0 ? getChild(count-1): null;
    }

    default Node getRoot() {
        Node parent = this;
        while (parent.getParent() != null ) {
            parent = parent.getParent();
        }
        return parent; 
    }
    
     static public List<Token> getTokens(Node node) {
        List<Token> result = new ArrayList<Token>();
        for (Node child : node.children()) {
            if (child instanceof Token) {
                result.add((Token) child);
            } else {
                result.addAll(getTokens(child));
            }
        }
        return result;
    }
        
        
    static public List<Token> getRealTokens(Node n) {
        List<Token> result = new ArrayList<Token>();
		for (Token token : getTokens(n)) {
		    if (!token.isUnparsed()) {
		        result.add(token);
		    }
		}
	    return result;
    }

    default List<Node> descendants() {
        return descendants(Node.class, null);
    }

    default List<Node> descendants(Predicate<? super Node> predicate) {
        return descendants(Node.class, predicate);
    }

    default <T extends Node> List<T> descendants(Class<T> clazz) {
        return descendants(clazz, null);
    }

    default <T extends Node> List<T> descendants(Class<T> clazz, Predicate<? super T> predicate) {
       List<T> result = new ArrayList<>();
       for (Node child : children()) {
          if (clazz.isInstance(child)) {
              T t = clazz.cast(child);
              if (predicate == null || predicate.test(t)) {
                  result.add(t);
              }
          }
          result.addAll(child.descendants(clazz, predicate)); 
       }
       return result;
    }

    default void dump(String prefix) {
        String output = (this instanceof Token) ? toString().trim() : getClass().getSimpleName();
[#if grammar.faultTolerant]
        if (this.isDirty()) {
            output += " (incomplete)";
        }
[/#if]
        if (output.length() >0) {
            System.out.println(prefix + output);
        }
        for (Iterator<Node> it = iterator(); it.hasNext();) {
            Node child = it.next();
            child.dump(prefix+"  ");
        }
    }

    default void dump() {
        dump("");
    }
[#if grammar.faultTolerant]    

    default boolean isDirty() {
        return false;
    }

    void setDirty(boolean dirty);

[/#if]    

    // NB: This is not thread-safe
    // If the node's children could change out from under you,
    // you could have a problem.

    default public ListIterator<Node> iterator() {
        return new ListIterator<Node>() {
            private int current = -1;
            private boolean justModified;
            
            public boolean hasNext() {
                return current+1 < getChildCount();
            }
            
            public Node next() {
                justModified = false;
                return getChild(++current);
            }
            
            public Node previous() {
                justModified = false;
                return getChild(--current);
            }
            
            public void remove() {
                if (justModified) throw new IllegalStateException();
                removeChild(current);
                --current;
                justModified = true;
            }
            
            public void add(Node n) {
                if (justModified) throw new IllegalStateException();
                addChild(current+1, n);
                justModified = true;
            }
            
            public boolean hasPrevious() {
                return current >0;
            }
            
            public int nextIndex() {
                return current + 1;
            }
            
            public int previousIndex() {
                return current;
            }
            
            public void set(Node n) {
                setChild(current, n);
            }
        };
    }

 	static abstract public class Visitor {
		
		static private Method baseVisitMethod;
		private HashMap<Class<? extends Node>, Method> methodCache = new HashMap<>();
		
		static private Method getBaseVisitMethod() throws NoSuchMethodException {
			if (baseVisitMethod == null) {
				baseVisitMethod = Node.Visitor.class.getMethod("visit", new Class[] {Node.class});
			} 
			return baseVisitMethod;
		}
		
		private Method getVisitMethod(Node node) {
			Class<? extends Node> nodeClass = node.getClass();
			if (!methodCache.containsKey(nodeClass)) {
				try {
					Method method = this.getClass().getMethod("visit", new Class[] {nodeClass});
					if (method.equals(getBaseVisitMethod())) {
						method = null; // Have to avoid infinite recursion, no?
					}
					methodCache.put(nodeClass, method);
				}
				catch (NoSuchMethodException nsme) {
					methodCache.put(nodeClass, null);
				}
			}
	        return methodCache.get(nodeClass);
		}
		
		/**
		 * Tries to invoke (via reflection) the appropriate visit(...) method
		 * defined in a subclass. If there is none, it just calls the fallback() routine.
         * @param node the Node to "visit" 
		 */
		public final void visit(Node node) {
			Method visitMethod = getVisitMethod(node);
			if (visitMethod == null) {
				fallback(node);
			} else try {
				visitMethod.invoke(this, new Object[] {node});
			} catch (InvocationTargetException ite) {
	    		Throwable cause = ite.getCause();
	    		if (cause instanceof RuntimeException) {
	    			throw (RuntimeException) cause;
	    		}
	    		throw new RuntimeException(ite);
	 		} catch (IllegalAccessException iae) {
	 			throw new RuntimeException(iae);
	 		}
		}

        /**
         * Just recurses over (i.e. visits) node's children
         * @param node the node we are traversing
         */
		
		public final void recurse(Node node) {
            for (Node child : node.children()) {
                visit(child);
            }
		}
		
		/**
		 * If there is no specific method to visit this node type,
		 * it just uses this method. The default base implementation
		 * is just to recurse over the nodes.
         * @param node The node we are currently traversing
		 */
		public void fallback(Node node) {
		    recurse(node);
		}
    }
}