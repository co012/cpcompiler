import nodes.*;
import parser.*;

import java.io.FileWriter;
import java.io.IOException;
import java.nio.file.Files;
import java.nio.file.LinkOption;
import java.nio.file.Path;
import java.util.List;
import java.util.Locale;

public class Launcher {
    public static void main(String[] args) throws IOException, ParseException {
        if(args.length < 1){
            System.out.println("No file to parse");
            return;
        }

        Path path = Path.of(args[0]);
        CPlusParser parser = new CPlusParser(path);
        parser.parse();
        Node root = parser.rootNode();
        if(!Files.exists(Path.of("out"), LinkOption.NOFOLLOW_LINKS))
            Files.createDirectory(Path.of("out"));

        List<ClassDefinition> classDefinitionList = root.descendantsOfType(ClassDefinition.class);
        for(ClassDefinition def : classDefinitionList){
            ASTUtility.changeClassToStruct(def);
        }

        List<Declaration> declarationList = root.descendantsOfType(Declaration.class);
        for (Declaration declaration: declarationList){
            if(ASTUtility.isAnClassDeclaration(declaration)){
                ASTUtility.convertClassDeclaration(declaration);
            }
        }

        TranslationUnit unit = (TranslationUnit) root;
        List<PostfixExpression> classExpressionList =
                root.descendantsOfType(PrimaryExpression.class).stream()
                        .filter(pe -> {
                            Token identifier = pe.firstChildOfType(CPlusConstants.TokenType.IDENTIFIER);
                            return identifier != null && unit.classIdentifiers.contains(identifier.getImage());
                        })
                        .map(pe -> pe.firstAncestorOfType(PostfixExpression.class))
                        .toList();

        for(PostfixExpression postfixExpression: classExpressionList){
            ASTUtility.convertPostfixExpression(postfixExpression);
        }

        FileWriter cFileWriter = new FileWriter("out/out.c");
        for(Token t: root.getAllTokens(true)){
            cFileWriter.write(t.getImage());
        }


        cFileWriter.flush();
        cFileWriter.close();

    }
}
