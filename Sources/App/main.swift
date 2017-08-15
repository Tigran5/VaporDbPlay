import Vapor
import VaporPostgreSQL
import Foundation
import Core
import HTTP

let drop = Droplet(providers: [VaporPostgreSQL.Provider.self])

class ArticleResponse {
    func getArticles(requset: Request) throws -> ResponseRepresentable {
        
        if let db = drop.database?.driver as? PostgreSQLDriver {
            
            let articles = try db.raw("select * from article")
            
            let response: Response = try Response(status: .ok, json: JSON(node: articles))
                
            return response
        } else {
            throw Abort.custom(status: .badRequest, message: "Article name is missing.")
        }
    }
    
    func postArticle(request: Request) throws -> ResponseRepresentable {
        guard request.formData?["article_name"] != nil || request.formData?["article_desc"] != nil else {
            throw Abort.custom(status: .badRequest, message: "Article name is missing.")
        }
        
        guard (request.formData?["article_name"]?.part.body.count)! > 0 else {
            throw Abort.custom(status: .badRequest, message: "Article name is missing.")
        }
        
        if let db = drop.database?.driver as? PostgreSQLDriver {
            // Geting String Data
            let articleNameByte = request.formData?["article_name"]?.part.body
            let articleDescByte = request.formData?["article_desc"]?.part.body
            
            let articleNameData = Data(articleNameByte!)
            let articleDescData = Data(articleDescByte!)
            
            let articleName = try articleNameData.string()
            let articleDesc = try articleDescData.string()

            var finalUrlString = ""
            
            if let bytes = request.formData?["image"]?.part.body {
                
                //Getting Image data
                let imageData = Data(bytes)
                
                let imageName = Int(arc4random_uniform(10000))
                debugPrint(imageName)
                
                let imageUrlString = "/Users/tigrantorgomyan/Documents/Sandbox/VaporPlayground/VaporDbPlay/Resources/Images/image-\(imageName).jpg"
                
                try imageData.write(to: URL(fileURLWithPath: imageUrlString))
                
                finalUrlString = "file://" + imageUrlString
            }
            
            
            let query = "insert into article(article_name, article_desc, article_imge_url) values ('\(articleName)', '\(articleDesc)', '\(finalUrlString)')"
            
            try db.raw(query)
            
            return try JSON(["Testawesome":"awesome123"])
        } else {
            return "No db"
        }
    }
    
    func getArticle(request: Request)  throws -> ResponseRepresentable {
        
        guard request.data["article_id"] != nil else {
            throw Abort.custom(status: .badRequest, message: "Article name is missing.")
        }
        
        if let db = drop.database?.driver as? PostgreSQLDriver {
            
            let articleId = request.data["article_id"]?.string
            
            let article = try db.raw("select * from article where article_id = \(articleId!)")
            
//            debugPrint(article.node)
            
            let response: Response = try Response(status: .ok, json: JSON(node: article[0]))
            
            return response
        }
        
        return ""
    }
}

enum ServiceError: Error {
    case NoAarticleNameError
}

final class User {
    func createUser(request: Request) throws -> ResponseRepresentable {
        
        guard request.data["user_email"] != nil else {
            let response: Response = try Response(status: .badRequest, json: JSON(node: ""))
            
            return response
        }
        
        let userEmail = request.data["user_email"]?.string
        let userName = request.data["user_name"]?.string
        let userPassword = request.data["user_password"]?.string
        
        let userToken = UUID()
        
        
        if let db = drop.database?.driver as? PostgreSQLDriver {
            let query = "insert into art_user(user_token, user_name, user_email, user_password) values ('\(userToken)', '\(userName!)', '\(userEmail!)', '\(userPassword!)')"
            
            try db.raw(query)
            
            let response: Response = try Response(status: .ok, json: JSON(node: ""))
            
            return response

        }
        
        return ""
    }
    
    func login(request: Request) throws -> ResponseRepresentable {
        let userEmail = request.data["user_email"]?.string
        let userPassword = request.data["user_password"]?.string
        
        if let db = drop.database?.driver as? PostgreSQLDriver {
            if let email = userEmail, let pass = userPassword {
                let query = "select user_token from art_user where  user_email = '\(email)' and user_password = '\(pass)'"
                
                let userToken = try db.raw(query)
                debugPrint(try db.raw(query))
                
                let response: Response = try Response(status: .ok, json: JSON(node: userToken))
                
                return response
            }

            
        }
        
        return ""
    }
}

final class ErrorMiddleware: Middleware {
    func respond(to request: Request, chainingTo next: Responder) throws -> Response {
        do {
            return try next.respond(to: request)
        } catch ServiceError.NoAarticleNameError {
            throw Abort.custom(
                status: .badRequest,
                message: "You should add article name."
            )
        }
    }
}


let articleResponse = ArticleResponse()
let user = User()

drop.middleware.append(ErrorMiddleware())

drop.get("articles", handler: articleResponse.getArticles)

drop.get("article", handler: articleResponse.getArticle)

drop.post("saveArticle", handler: articleResponse.postArticle)

drop.post("createuser", handler: user.createUser)

drop.post("login", handler: user.login)











//// Wrong way to do requsets
//
//drop.post("saveArticle") { request in
//    guard request.formData?["article_name"] != nil || request.formData?["article_desc"] != nil else {
//        return Abort.custom(status: .badRequest, message: "Missed Article Name") as! ResponseRepresentable
//    }
//    
//    
//    if let db = drop.database?.driver as? PostgreSQLDriver {
//        if let bytes = request.formData?["image"]?.part.body {
//            
//            // Geting String Data
//            let articleNameByte = request.formData?["article_name"]?.part.body
//            let articleDescByte = request.formData?["article_desc"]?.part.body
//            
//            let articleNameData = Data(articleNameByte!)
//            let articleDescData = Data(articleDescByte!)
//            
//            let articleName = try articleNameData.string()
//            let articleDesc = try articleDescData.string()
//            
//            //Getting Image data
//            let imageData = Data(bytes)
//            
//            let imageName = Int(arc4random_uniform(100))
//            debugPrint(imageName)
//            
//            let imageUrlString = "/Users/tigrantorgomyan/Documents/Sandbox/VaporPlayground/VaporDbPlay/Resources/Images/image-\(imageName).jpg"
//            
//            try imageData.write(to: URL(fileURLWithPath: imageUrlString))
//            
//            let finalUrlString = "file://" + imageUrlString
//            
//            let query = "insert into article(article_name, article_desc, article_imge_url) values ('\(articleName)', '\(articleDesc)', '\(finalUrlString)')"
//            
//            let article = try db.raw(query)
//            
//            return try JSON(node: article)
//        }
//        
//        return try JSON(["Testawesome":"awesome123"])
//    } else {
//        return "No db"
//    }
//}
//

//drop.get("articles") { request in
//    if let db = drop.database?.driver as? PostgreSQLDriver {
//        let version = try db.raw("select * from article")
//        return try JSON(node: version)
//    } else {
//        return "No db"
//    }
//}

//drop.post("saveimage") { request in
//    if let bytes = request.formData?["image"]?.part.body {
//        debugPrint(Data(bytes))
//        let imageData = Data(bytes)
//        
//        let imageName = Int(arc4random_uniform(100000))
//        debugPrint(imageName)
//        
//        try imageData.write(to: URL(fileURLWithPath: "/Users/tigrantorgomyan/Documents/Sandbox/VaporPlayground/VaporDbPlay/Resources/Images/image-\(imageName).jpg"))
//        
//        return JSON(["Testawesome":"awesome123"])
//    }
//    return JSON(["test":"123"])
//}
//
//drop.post("saveArticleOld") { request in
//    if let db = drop.database?.driver as? PostgreSQLDriver {
//        let name = request.data["article_name"]?.string!
//        let description = request.data["article_desc"]?.string!
//        
//        let query = "insert into article(article_name, article_desc, article_imge_url) values ('\(name!)', '\(description!)', 'http://10.0.0.11/BunBerRes/Common/GetImage?T=BillboardImage&C=L&N=74773c2055f7467190bbe0a6fffc5646')"
//        
//        let version = try db.raw(query)
//        
//        return try JSON(node: version)
//    } else {
//        return "No db"
//    }
//}

drop.run()
