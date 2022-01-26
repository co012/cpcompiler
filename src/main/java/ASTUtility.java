import nodes.*;
import parser.CPlusConstants;
import parser.CPlusLexer;
import parser.Node;
import parser.Token;

import java.util.List;
import java.util.Optional;
import static parser.CPlusConstants.TokenType.*;

public class ASTUtility {

    public static void changeClassToStruct(ClassDefinition classDefinition){
        // ClassDefinition : <CLASS> <IDENTIFIER> "{" [StructDeclarationList] (FunctionDefinition)* "}" ;
        String className = getClassName(classDefinition);
        StructDeclarationList structDeclarationList = classDefinition.firstChildOfType(StructDeclarationList.class);
        List<FunctionDefinition> functionDefinitionList = classDefinition.childrenOfType(FunctionDefinition.class);
        Token first = classDefinition.getFirstToken();
        while (first.isUnparsed())first = first.getNext();
        Token last = classDefinition.getLastToken();
        classDefinition.clearChildren();


        if(structDeclarationList != null)
            classDefinition.addChild(createStruct(structDeclarationList, getStructName(className)));

        classDefinition.getFirstToken().copyLocationInfo(first);

        for(FunctionDefinition definition : functionDefinitionList){
            convertMethod2Function(definition, className);
            classDefinition.addChild(definition);
        }

        classDefinition.getLastToken().copyLocationInfo(last);

    }

    private static String getStructName(String className) {
        return className + "Attributes";
    }

    private static String getClassName(ClassDefinition classDefinition) {
        Token classNameToke = classDefinition.firstChildOfType(CPlusConstants.TokenType.IDENTIFIER);
        return classNameToke.getImage();
    }

    private static Node createStruct(StructDeclarationList declarationList, String structName){
        StructOrUnionSpecifier structOrUnionSpecifier = new StructOrUnionSpecifier();
        structOrUnionSpecifier.addChild(Token.newToken(STRUCT,"struct", null));
        structOrUnionSpecifier.addChild(Token.newToken(WHITESPACE," ", null));
        structOrUnionSpecifier.addChild(Token.newToken(IDENTIFIER,structName, null));
        structOrUnionSpecifier.addChild(Token.newToken(WHITESPACE," ", null));
        structOrUnionSpecifier.addChild(Token.newToken(LBRACE,"{", null));
        structOrUnionSpecifier.addChild(declarationList);
        structOrUnionSpecifier.addChild(Token.newToken(WHITESPACE,"\n", null));
        structOrUnionSpecifier.addChild(Token.newToken(RBRACE,"}", null));
        structOrUnionSpecifier.addChild(Token.newToken(SEMICOLON,";", null));
        return structOrUnionSpecifier;
    }

    private static void convertMethod2Function(FunctionDefinition definition, String className){
        // FunctionDefinition : DeclarationSpecifiers Declarator [DeclarationList] CompoundStatement
        convertDeclarator(definition.firstChildOfType(Declarator.class), className);
        definition.getAllTokens(true).stream()
                .filter(token -> token.getType().equals(CPlusConstants.TokenType.WHITESPACE))
                .forEach(token -> token.setImage(token.getImage().replaceAll("\\n {4}","")));

        convertCompoundStatement(definition.firstChildOfType(CompoundStatement.class), className);
    }

    private static void convertDeclarator(Declarator declarator, String className){
        Optional.ofNullable(
                declarator.firstChildOfType(DirectDeclarator.class)
                .firstChildOfType(CPlusConstants.TokenType.IDENTIFIER)
                ).ifPresent(token -> token.setImage(className + "_" + token.getImage()));

        insertThisParameter(declarator, getStructName(className));

    }

    private static void insertThisParameter(Declarator declarator, String structName) {
        Node thisParameter = getThisParameter(structName);

        ParameterList parameterList = declarator.firstDescendantOfType(ParameterList.class);
        ParameterDeclaration declaration = parameterList.firstChildOfType(ParameterDeclaration.class);
        if(parameterList.children().size() == 1){

            if(declaration.getLastToken().getType().equals(CPlusConstants.TokenType.VOID)){
                parameterList.clearChildren();
                parameterList.addChild(thisParameter);
                return;
            }
        }

        parameterList.prependChild(declaration, thisParameter);
        parameterList.prependChild(declaration, Token.newToken(CPlusConstants.TokenType._TOKEN_4, ",", null));
    }

    private static Node getThisParameter(String structName) {
        Node thisParameter = new ParameterDeclaration();
        thisParameter.addChild(Token.newToken(CPlusConstants.TokenType.STRUCT, "struct", null));
        thisParameter.addChild(Token.newToken(CPlusConstants.TokenType.WHITESPACE, " ", null));
        thisParameter.addChild(Token.newToken(CPlusConstants.TokenType.IDENTIFIER, structName, null));
        thisParameter.addChild(Token.newToken(CPlusConstants.TokenType._TOKEN_3, "*", null));
        thisParameter.addChild(Token.newToken(CPlusConstants.TokenType.WHITESPACE, " ", null));
        thisParameter.addChild(Token.newToken(CPlusConstants.TokenType.IDENTIFIER, "this", null));
        return thisParameter;
    }

    private static void convertCompoundStatement(CompoundStatement statement, String className){
        List<PrimaryThisExpression> primaryThisExpressionList
                = statement.descendantsOfType(PrimaryThisExpression.class);

        for(PrimaryThisExpression thisExpression : primaryThisExpressionList){
            PostfixExpression postfixExpression = thisExpression.firstAncestorOfType(PostfixExpression.class);
            PostfixExpressionPrim postfixExpressionPrim
                    = postfixExpression.firstChildOfType(PostfixExpressionPrim.class);
            if(postfixExpressionPrim != null && isAnFunctionCall(postfixExpressionPrim)){

                Token thisToken = thisExpression.firstChildOfType(THIS);
                List<Token> unparsed=thisToken.precedingUnparsedTokens();
                thisExpression.removeChild(thisToken);
                Token pointToken = thisExpression.firstChildOfType(POINT);
                thisExpression.removeChild(pointToken);
                Token identifier = thisExpression.firstChildOfType(IDENTIFIER);
                identifier.setImage(className + "_" + identifier.getImage());
                identifier.preInsert(unparsed.get(0));


                postfixExpressionPrim.addChild(1,Token.newToken(IDENTIFIER, "this",null));
                if(postfixExpressionPrim.firstChildOfType(ArgumentExpressionList.class) != null){
                    postfixExpressionPrim.addChild(2, Token.newToken(COMMA,", ",null));
                }
            }else{
                Token point = thisExpression.firstChildOfType(POINT);
                thisExpression.replaceChild(point,Token.newToken(_TOKEN_107, "->",null));
            }

        }

    }

    private static boolean isAnFunctionCall(PostfixExpressionPrim postfixExpressionPrim){
        return postfixExpressionPrim.firstChildOfType(LPAREN) != null;
    }

    public static boolean isAnClassDeclaration(Declaration declaration){
        return declaration.firstDescendantOfType(ClassSpecifier.class) != null;
    }

    public static void convertClassDeclaration(Declaration declaration){
        ClassSpecifier specifier = declaration.firstDescendantOfType(ClassSpecifier.class);
        Token classToken = specifier.firstChildOfType(CLASS);
        Token structToken = Token.newToken(STRUCT, "struct", null);
        structToken.copyLocationInfo(classToken);
        specifier.replaceChild(classToken, structToken);
        Token className = specifier.firstChildOfType(IDENTIFIER);
        String classNameString = className.getImage();
        className.setImage(className.getImage() + "Attributes");

        DirectDeclarator directDeclarator = declaration.firstDescendantOfType(DirectDeclarator.class);
        Token identifier = directDeclarator.firstChildOfType(IDENTIFIER);

        CompoundStatement statement = declaration.firstAncestorOfType(CompoundStatement.class);
        TranslationUnit unit = declaration.firstAncestorOfType(TranslationUnit.class);
        if(statement == null){
            unit.addIdentifierClassNameEntry(identifier.getImage(), classNameString);
        }else{
            statement.addIdentifierClassNameEntry(identifier.getImage(), classNameString);
        }

        unit.classIdentifiers.add(identifier.getImage());
    }

    private static String getClassName(String identifier, Node start){
        CompoundStatement compoundStatement = start.firstAncestorOfType(CompoundStatement.class);
        if(compoundStatement != null){
            return compoundStatement.getClassName(identifier).orElseThrow();
        }else{
            TranslationUnit unit = start.firstAncestorOfType(TranslationUnit.class);
            return unit.getClassName(identifier).orElseThrow();
        }
    }

    private static boolean isAnFunction(PostfixExpression postfixExpression){
        PostfixExpressionPrim prim = postfixExpression.firstDescendantOfType(PostfixExpressionPrim.class);
        if(prim == null) return false;
        PostfixExpressionPrim primPrim = prim.firstChildOfType(PostfixExpressionPrim.class);
        if(primPrim == null) return false;

        return primPrim.firstChildOfType(LPAREN) != null;
    }

    public static void convertPostfixExpression(PostfixExpression postfixExpression) {
        PrimaryExpression primaryExpression = postfixExpression.firstDescendantOfType(PrimaryExpression.class);
        String identifier = primaryExpression.firstChildOfType(IDENTIFIER).getImage();
        String className = getClassName(identifier, postfixExpression);

        if(!isAnFunction(postfixExpression)) return;

        String functionName = postfixExpression.firstDescendantOfType(PostfixExpressionPrim.class)
                .firstChildOfType(IDENTIFIER)
                .getImage();

        ArgumentExpressionList argumentExpressionList =
                postfixExpression.firstDescendantOfType(ArgumentExpressionList.class);

        Token first = postfixExpression.getFirstToken();
        while (first.isUnparsed()) first = first.getNext();
        Token last = postfixExpression.getLastToken();

        Token functionIdentifier = Token.newToken(IDENTIFIER, className + "_" + functionName, null);
        functionIdentifier.copyLocationInfo(first);
        PrimaryExpression primaryExpressionNew = new PrimaryExpression();
        primaryExpressionNew.addChild(primaryExpressionNew);

        ArgumentExpressionList argumentExpressionListNew = new ArgumentExpressionList();
        Token lParen = Token.newToken(LPAREN, "(", null);
        argumentExpressionListNew.addChild(lParen);
        argumentExpressionListNew.addChild(Token.newToken(IDENTIFIER, "&" + identifier, null));
        if(argumentExpressionList != null){
            argumentExpressionListNew.addChild(Token.newToken(COMMA, ", ",null));
            argumentExpressionList.children(true).forEach(argumentExpressionListNew::addChild);
        }
        Token rParen = Token.newToken(RPAREN, ")", null);
        argumentExpressionListNew.addChild(rParen);
        rParen.copyLocationInfo(last);

        postfixExpression.clearChildren();
        functionIdentifier.copyLocationInfo(first);
        postfixExpression.addChild(functionIdentifier);
        postfixExpression.addChild(argumentExpressionListNew);

    }
}
