import Testing
import Foundation
import URLRouting

@Suite("FileUpload Tests")
struct FileUploadTests {

    // MARK: - Initialization Tests

    @Test("Create FileUpload with valid parameters")
    func testValidInitialization() throws {
        let fileUpload = try FileUpload(
            fieldName: "document",
            filename: "report.pdf",
            fileType: .pdf
        )

        #expect(fileUpload.fieldName == "document")
        #expect(fileUpload.filename == "report.pdf")
        #expect(fileUpload.maxSize == FileUpload.maxFileSize)
    }

    @Test("Create FileUpload with custom max size")
    func testCustomMaxSize() throws {
        let customSize = Measurement(value: 5, unit: UnitInformationStorage.mebibytes)
        let fileUpload = try FileUpload(
            fieldName: "photo",
            filename: "image.jpg",
            fileType: .image(.jpeg),
            maxSize: customSize
        )

        #expect(fileUpload.maxSize == customSize)
    }

    @Test("Empty field name throws error")
    func testEmptyFieldNameThrows() throws {
        #expect(throws: FileUpload.Error.self) {
            try FileUpload(
                fieldName: "",
                filename: "file.pdf",
                fileType: .pdf
            )
        }
    }

    @Test("Empty filename throws error")
    func testEmptyFilenameThrows() throws {
        #expect(throws: FileUpload.Error.self) {
            try FileUpload(
                fieldName: "document",
                filename: "",
                fileType: .pdf
            )
        }
    }

    @Test("Filename with forward slash throws error")
    func testFilenameWithForwardSlashThrows() throws {
        #expect(throws: FileUpload.Error.self) {
            try FileUpload(
                fieldName: "document",
                filename: "path/to/file.pdf",
                fileType: .pdf
            )
        }
    }

    @Test("Filename with backslash throws error")
    func testFilenameWithBackslashThrows() throws {
        #expect(throws: FileUpload.Error.self) {
            try FileUpload(
                fieldName: "document",
                filename: "path\\to\\file.pdf",
                fileType: .pdf
            )
        }
    }

    @Test("Zero max size throws error")
    func testZeroMaxSizeThrows() throws {
        #expect(throws: FileUpload.Error.self) {
            try FileUpload(
                fieldName: "document",
                filename: "file.pdf",
                fileType: .pdf,
                maxSize: Measurement(value: 0, unit: .bytes)
            )
        }
    }

    @Test("Negative max size throws error")
    func testNegativeMaxSizeThrows() throws {
        #expect(throws: FileUpload.Error.self) {
            try FileUpload(
                fieldName: "document",
                filename: "file.pdf",
                fileType: .pdf,
                maxSize: Measurement(value: -1, unit: .bytes)
            )
        }
    }

    @Test("Max size exceeding 1 GiB throws error")
    func testMaxSizeExceedsLimitThrows() throws {
        let overLimit = Measurement(value: 1.1, unit: UnitInformationStorage.gibibytes)
        #expect(throws: FileUpload.Error.self) {
            try FileUpload(
                fieldName: "document",
                filename: "file.pdf",
                fileType: .pdf,
                maxSize: overLimit
            )
        }
    }

    // MARK: - Validation Tests

    @Test("Validate empty data throws error")
    func testValidateEmptyDataThrows() throws {
        let fileUpload = try FileUpload(
            fieldName: "document",
            filename: "file.pdf",
            fileType: .pdf
        )

        #expect(throws: FileUpload.Error.self) {
            try fileUpload.validate(Data())
        }
    }

    @Test("Validate oversized file throws error")
    func testValidateOversizedFileThrows() throws {
        let maxSize = Measurement(value: 1, unit: UnitInformationStorage.kibibytes)
        let fileUpload = try FileUpload(
            fieldName: "document",
            filename: "file.pdf",
            fileType: .pdf,
            maxSize: maxSize
        )

        let largeData = Data(repeating: 0, count: 1025)  // 1025 bytes > 1 KiB (1024 bytes)
        #expect(throws: FileUpload.Error.self) {
            try fileUpload.validate(largeData)
        }
    }

    @Test("Validate PDF with correct magic number succeeds")
    func testValidatePDFWithCorrectMagicNumber() throws {
        let fileUpload = try FileUpload(
            fieldName: "document",
            filename: "file.pdf",
            fileType: .pdf
        )

        let pdfData = "%PDF-1.4\n".data(using: .utf8)!
        #expect(throws: Never.self) {
            try fileUpload.validate(pdfData)
        }
    }

    @Test("Validate PDF with incorrect magic number throws error")
    func testValidatePDFWithIncorrectMagicNumberThrows() throws {
        let fileUpload = try FileUpload(
            fieldName: "document",
            filename: "file.pdf",
            fileType: .pdf
        )

        let invalidData = "not a pdf".data(using: .utf8)!
        #expect(throws: FileUpload.Error.self) {
            try fileUpload.validate(invalidData)
        }
    }

    @Test("Validate CSV with valid UTF-8 succeeds")
    func testValidateCSVWithValidUTF8() throws {
        let fileUpload = try FileUpload(
            fieldName: "data",
            filename: "data.csv",
            fileType: .csv
        )

        let csvData = "name,age\nJohn,30\nJane,25".data(using: .utf8)!
        #expect(throws: Never.self) {
            try fileUpload.validate(csvData)
        }
    }

    @Test("Validate file within size limit succeeds")
    func testValidateFileWithinSizeLimit() throws {
        let maxSize = Measurement(value: 1, unit: UnitInformationStorage.kibibytes)
        let fileUpload = try FileUpload(
            fieldName: "document",
            filename: "file.txt",
            fileType: .text,
            maxSize: maxSize
        )

        let validData = Data(repeating: 0, count: Int(maxSize.converted(to: .bytes).value))
        #expect(throws: Never.self) {
            try fileUpload.validate(validData)
        }
    }

    // MARK: - Content-Type Tests

    @Test("Content-Type includes multipart/form-data")
    func testContentTypeMultipartFormData() throws {
        let fileUpload = try FileUpload(
            fieldName: "document",
            filename: "file.pdf",
            fileType: .pdf
        )

        let contentType = fileUpload.contentType
        #expect(contentType.type == "multipart")
        #expect(contentType.subtype == "form-data")
    }

    @Test("Content-Type includes boundary parameter")
    func testContentTypeIncludesBoundary() throws {
        let fileUpload = try FileUpload(
            fieldName: "document",
            filename: "file.pdf",
            fileType: .pdf
        )

        let contentType = fileUpload.contentType
        #expect(contentType.parameters["boundary"] != nil)
        #expect(!contentType.parameters["boundary"]!.isEmpty)
    }

    @Test("Each FileUpload has unique boundary")
    func testUniqueBoundaries() throws {
        let fileUpload1 = try FileUpload(
            fieldName: "document",
            filename: "file1.pdf",
            fileType: .pdf
        )

        let fileUpload2 = try FileUpload(
            fieldName: "document",
            filename: "file2.pdf",
            fileType: .pdf
        )

        let boundary1 = fileUpload1.contentType.parameters["boundary"]!
        let boundary2 = fileUpload2.contentType.parameters["boundary"]!

        #expect(boundary1 != boundary2)
    }

    // MARK: - File Type Tests

    @Test("Different file types have correct extensions")
    func testFileTypeExtensions() throws {
        struct TestCase {
            let fileType: FileUpload.FileType
            let expectedExtension: String
        }

        let testCases: [TestCase] = [
            TestCase(fileType: .pdf, expectedExtension: "pdf"),
            TestCase(fileType: .csv, expectedExtension: "csv"),
            TestCase(fileType: .json, expectedExtension: "json"),
            TestCase(fileType: .text, expectedExtension: "txt"),
            TestCase(fileType: .excel, expectedExtension: "xlsx"),
            TestCase(fileType: .docx, expectedExtension: "docx"),
            TestCase(fileType: .doc, expectedExtension: "doc"),
            TestCase(fileType: .zip, expectedExtension: "zip"),
            TestCase(fileType: .mp3, expectedExtension: "mp3"),
            TestCase(fileType: .wav, expectedExtension: "wav"),
            TestCase(fileType: .mp4, expectedExtension: "mp4"),
            TestCase(fileType: .sqlite, expectedExtension: "sqlite"),
            TestCase(fileType: .swift, expectedExtension: "swift"),
            TestCase(fileType: .javascript, expectedExtension: "js"),
            TestCase(fileType: .ttf, expectedExtension: "ttf"),
            TestCase(fileType: .svg, expectedExtension: "svg"),
        ]

        for testCase in testCases {
            #expect(testCase.fileType.fileExtension == testCase.expectedExtension)
        }
    }

    @Test("Image file types have correct extensions")
    func testImageFileTypeExtensions() throws {
        struct TestCase {
            let imageType: FileUpload.FileType.ImageType
            let expectedExtension: String
        }

        let testCases: [TestCase] = [
            TestCase(imageType: .jpeg, expectedExtension: "jpg"),
            TestCase(imageType: .png, expectedExtension: "png"),
            TestCase(imageType: .gif, expectedExtension: "gif"),
            TestCase(imageType: .webp, expectedExtension: "webp"),
        ]

        for testCase in testCases {
            let fileType = FileUpload.FileType.image(testCase.imageType)
            #expect(fileType.fileExtension == testCase.expectedExtension)
        }
    }

    // MARK: - Error Description Tests

    @Test("Error descriptions are user-friendly")
    func testErrorDescriptions() throws {
        let errors: [FileUpload.Error] = [
            .fileTooLarge(
                size: Measurement(value: 2000, unit: .bytes),
                maxSize: Measurement(value: 1000, unit: .bytes)
            ),
            .invalidContentType("invalid/type"),
            .contentMismatch(expected: "application/pdf", detected: "text/plain"),
            .emptyData,
            .malformedBoundary,
            .encodingError,
            .emptyFieldName,
            .emptyFilename,
            .invalidFilename("path/file.txt"),
            .invalidMaxSize(Measurement(value: -1, unit: .bytes)),
            .maxSizeExceedsLimit(Measurement(value: 2, unit: UnitInformationStorage.gibibytes)),
        ]

        for error in errors {
            #expect(error.errorDescription != nil)
            #expect(!error.errorDescription!.isEmpty)
        }
    }

    // MARK: - Integration Tests

    @Test("FileUpload works with different file types")
    func testFileUploadWithDifferentTypes() throws {
        struct TestCase {
            let fileType: FileUpload.FileType
            let filename: String
        }

        let testCases: [TestCase] = [
            TestCase(fileType: .pdf, filename: "document.pdf"),
            TestCase(fileType: .csv, filename: "data.csv"),
            TestCase(fileType: .json, filename: "config.json"),
            TestCase(fileType: .image(.png), filename: "photo.png"),
        ]

        for testCase in testCases {
            let fileUpload = try FileUpload(
                fieldName: "file",
                filename: testCase.filename,
                fileType: testCase.fileType
            )

            #expect(fileUpload.filename == testCase.filename)
        }
    }

    @Test("FileUpload max size defaults correctly")
    func testDefaultMaxSize() throws {
        let fileUpload = try FileUpload(
            fieldName: "document",
            filename: "file.pdf",
            fileType: .pdf
        )

        let expectedSize = Measurement(value: 10, unit: UnitInformationStorage.mebibytes)
        #expect(fileUpload.maxSize == expectedSize)
    }

    @Test("FileUpload validates at exact max size")
    func testValidateAtExactMaxSize() throws {
        let maxSize = Measurement(value: 1, unit: UnitInformationStorage.kibibytes)
        let fileUpload = try FileUpload(
            fieldName: "document",
            filename: "file.txt",
            fileType: .text,
            maxSize: maxSize
        )

        let exactData = Data(repeating: 0, count: Int(maxSize.converted(to: .bytes).value))
        #expect(throws: Never.self) {
            try fileUpload.validate(exactData)
        }
    }

    @Test("FileUpload error equality works")
    func testErrorEquality() throws {
        let error1 = FileUpload.Error.fileTooLarge(
            size: Measurement(value: 1000, unit: .bytes),
            maxSize: Measurement(value: 500, unit: .bytes)
        )
        let error2 = FileUpload.Error.fileTooLarge(
            size: Measurement(value: 1000, unit: .bytes),
            maxSize: Measurement(value: 500, unit: .bytes)
        )
        let error3 = FileUpload.Error.fileTooLarge(
            size: Measurement(value: 2000, unit: .bytes),
            maxSize: Measurement(value: 500, unit: .bytes)
        )

        #expect(error1 == error2)
        #expect(error1 != error3)
    }
}
