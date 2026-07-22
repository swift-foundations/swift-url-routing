import Foundation
import typealias HTML_Standard.HTML
import RFC_2046
import Testing
import URLRouting

@Suite
struct `Body Coder Route Tests` {
    struct MultipartValue: Codable, Equatable {
        let name: String
    }

    @Test
    func `form coding adds only its content type`() throws {
        let value = ["name": "Jane", "age": "30"]
        let coded = URLRouting.Body<[String: String]>(
            coding: .form([String: String].self)
        )

        var codedRequest = RFC_3986.URI.Request.Data()
        try coded.serialize(value, into: &codedRequest)

        #expect(codedRequest.body?.isEmpty == false)
        #expect(
            codedRequest.headers["Content-Type"]?.first
                == "application/x-www-form-urlencoded"
        )
        #expect(try coded.parse(&codedRequest) == value)
        #expect(codedRequest.headers["Content-Type"] == nil)
    }

    @Test
    func `JSON coding adds only its content type`() throws {
        let value = ["message": "hello"]
        let conversion = Parser.Conversion.JSON<[String: String]>()
        let legacy = HTTP.Body.Parser(conversion)
        let coded = URLRouting.Body<[String: String]>(
            coding: .json([String: String].self)
        )

        var legacyRequest = RFC_3986.URI.Request.Data()
        try legacy.serialize(value, into: &legacyRequest)

        var codedRequest = RFC_3986.URI.Request.Data()
        try coded.serialize(value, into: &codedRequest)

        #expect(codedRequest.body == legacyRequest.body)
        #expect(codedRequest.headers["Content-Type"]?.first == "application/json")
        #expect(try coded.parse(&codedRequest) == value)
        #expect(codedRequest.headers["Content-Type"] == nil)
    }

    @Test
    func `multipart coding carries and decodes the realized boundary`() throws {
        let value = MultipartValue(name: "Jane")
        let emittedBoundary = try RFC_2046.Boundary("B4EmittedBoundary")
        let otherBoundary = try RFC_2046.Boundary("B4OtherBoundary")
        let conversion = HTML.Form.Coder.Multipart.Value(
            MultipartValue.self,
            boundary: emittedBoundary
        )
        let coded = URLRouting.Body<MultipartValue>(coding: conversion)

        var codedRequest = RFC_3986.URI.Request.Data()
        try coded.serialize(value, into: &codedRequest)

        #expect(codedRequest.body?.isEmpty == false)
        #expect(
            codedRequest.headers["Content-Type"]?.first
                == "multipart/form-data; boundary=B4EmittedBoundary"
        )

        let parser = URLRouting.Body<MultipartValue>(
            coding: HTML.Form.Coder.Multipart.Value(
                MultipartValue.self,
                boundary: otherBoundary
            )
        )
        let decoded = try parser.parse(&codedRequest)
        #expect(decoded == value)
        #expect(codedRequest.headers["Content-Type"] == nil)
    }

    @Test
    func `coding rejects a missing or unacceptable content type`() throws {
        let coded = URLRouting.Body<[String: String]>(
            coding: .form([String: String].self)
        )
        let body = Foundation.Data("name=Jane".utf8)

        var missing = RFC_3986.URI.Request.Data(body: body)
        #expect(throws: RFC_3986.URI.Routing.Error.self) {
            try coded.parse(&missing)
        }

        var unacceptable = RFC_3986.URI.Request.Data(
            headers: ["Content-Type": ["application/json"]],
            body: body
        )
        #expect(throws: RFC_3986.URI.Routing.Error.self) {
            try coded.parse(&unacceptable)
        }
    }
}
