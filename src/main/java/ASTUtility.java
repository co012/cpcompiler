import nodes.*;
import parser.CPlusConstants;
import parser.CPlusLexer;
import parser.Node;
import parser.Token;

import java.util.List;
import java.util.Optional;

public class ASTUtility {

    public static void changeClassToStruct(ClassDefinition classDefinition){
        // ClassDefinition : <CLASS> <IDENTIFIER> "{" [StructDeclarationList] (FunctionDefinition)* "}" ;
        String className = getClassName(classDefinition);
        StructDeclarationList structDeclarationList = classDefinition.firstChildOfType(StructDeclarationList.class);
        List<FunctionDefinition> functionDefinitionList = classDefinition.childrenOfType(FunctionDefinition.class);
        classDefinition.clearChildren();

        if(structDeclarationList != null)
            classDefinition.addChild(createStruct(structDeclarationList, getStructName(className)));

        for(FunctionDefinition definition : functionDefinitionList){
            convertMethod2Function(definition, className);
            classDefinition.addChild(definition);
        }

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
        structOrUnionSpecifier.addChild(Token.newToken(CPlusConstants.TokenType.STRUCT,"struct", null));
        structOrUnionSpecifier.addChild(Token.newToken(CPlusConstants.TokenType.WHITESPACE," ", null));
        structOrUnionSpecifier.addChild(Token.newToken(CPlusConstants.TokenType.IDENTIFIER,structName, null));
        structOrUnionSpecifier.addChild(Token.newToken(CPlusConstants.TokenType.WHITESPACE," ", null));
        structOrUnionSpecifier.addChild(Token.newToken(CPlusConstants.TokenType._TOKEN_68,"{", null));
        structOrUnionSpecifier.addChild(declarationList);
        structOrUnionSpecifier.addChild(Token.newToken(CPlusConstants.TokenType.WHITESPACE,"\n", null));
        structOrUnionSpecifier.addChild(Token.newToken(CPlusConstants.TokenType._TOKEN_69,"}", null));
        structOrUnionSpecifier.addChild(Token.newToken(CPlusConstants.TokenType._TOKEN_3,";", null));
        return structOrUnionSpecifier;
    }

    private static void convertMethod2Function(FunctionDefinition definition, String className){
        // FunctionDefinition : DeclarationSpecifiers Declarator [DeclarationList] CompoundStatement
        convertDeclarator(definition.firstChildOfType(Declarator.class), className);
        definition.getAllTokens(true).stream()
                .filter(token -> token.getType().equals(CPlusConstants.TokenType.WHITESPACE))
                .forEach(token -> token.setImage(token.getImage().replaceAll("\\n {4}","")));
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

    private static void convertCompoundStatement(CompoundStatement statement){

    }


}
