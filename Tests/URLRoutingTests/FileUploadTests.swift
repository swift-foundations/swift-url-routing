import Testing
import Foundation
import URLRouting

@Suite
struct Test {

    // MARK: - Initialization Tests

    @Test
    func `Create File Upload with valid parameters`() throws {
        let fileUpload = try FileUpload(
            fieldName: "document",
            filename: "report.pdf",
            fileType: .pdf
        )

        #expect(fileUpload.fieldName == "document")
        #expect(fileUpload.filename == "report.pdf")
        #expect(fileUpload.maxSize == FileUpload.maxFileSize)
    }

    @Test
    func `Create File Upload with custom max size`() throws {
        let customSize = Measurement(value: 5, unit: UnitInformationStorage.mebibytes)
        let fileUpload = try FileUpload(
            fieldName: "photo",
            filename: "image.jpg",
            fileType: .image(.jpeg),
            maxSize: customSize
        )

        #expect(fileUpload.maxSize == customSize)
    }

    @Test
    func `Empty field name throws error`() throws {
        #expect(throws: FileUpload.Error.self) {
            try FileUpload(
                fieldName: "",
                filename: "file.pdf",
                fileType: .pdf
            )
        }
    }

    @Test
    func `Empty filename throws error`() throws {
        #expect(throws: FileUpload.Error.self) {
            try FileUpload(
                fieldName: "document",
                filename: "",
                fileType: .pdf
            )
        }
    }

    @Test
    func `Filename with forward slash throws error`() throws {
        #expect(throws: FileUpload.Error.self) {
            try FileUpload(
                fieldName: "document",
                filename: "path/to/file.pdf",
                fileType: .pdf
            )
        }
    }

    @Test
    func `Filename with backslash throws error`() throws {
        #expect(throws: FileUpload.Error.self) {
            try FileUpload(
                fieldName: "document",
                filename: "path\\to\\file.pdf",
                fileType: .pdf
            )
        }
    }

    @Test
    func `Zero max size throws error`() throws {
        #expect(throws: FileUpload.Error.self) {
            try FileUpload(
                fieldName: "document",
                filename: "file.pdf",
                fileType: .pdf,
                maxSize: Measurement(value: 0, unit: .bytes)
            )
        }
    }

    @Test
    func `Negative max size throws error`() throws {
        #expect(throws: FileUpload.Error.self) {
            try FileUpload(
                fieldName: "document",
                filename: "file.pdf",
                fileType: .pdf,
                maxSize: Measurement(value: -1, unit: .bytes)
            )
        }
    }

    @Test
    func `Max size exceeding 1 Gi B throws error`() throws {
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

    @Test
    func `Validate empty data throws error`() throws {
        let fileUpload = try FileUpload(
            fieldName: "document",
            filename: "file.pdf",
            fileType: .pdf
        )

        #expect(throws: FileUpload.Error.self) {
            try fileUpload.validate(Data())
        }
    }

    @Test
    func `Validate oversized file throws error`() throws {
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

    @Test
    func `Validate PDF with correct magic number succeeds`() throws {
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

    @Test
    func `Validate PDF with incorrect magic number throws error`() throws {
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

    @Test
    func `Validate CSV with valid UTF-8 succeeds`() throws {
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

    @Test
    func `Validate file within size limit succeeds`() throws {
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

    @Test
    func `Content-Type includes multipart/form-data`() throws {
        let fileUpload = try FileUpload(
            fieldName: "document",
            filename: "file.pdf",
            fileType: .pdf
        )

        let contentType = fileUpload.contentType
        #expect(contentType.type == "multipart")
        #expect(contentType.subtype == "form-data")
    }

    @Test
    func `Content-Type includes boundary parameter`() throws {
        let fileUpload = try FileUpload(
            fieldName: "document",
            filename: "file.pdf",
            fileType: .pdf
        )

        let contentType = fileUpload.contentType
        #expect(contentType.parameters[.boundary] != nil)
        #expect(!contentType.parameters[.boundary]!.isEmpty)
    }

    @Test
    func `Each File Upload has unique boundary`() throws {
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

        let boundary1 = fileUpload1.contentType.parameters[.boundary]!
        let boundary2 = fileUpload2.contentType.parameters[.boundary]!

        #expect(boundary1 != boundary2)
    }

    // MARK: - File Type Tests

    @Test
    func `Different file types have correct extensions`() throws {
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

    @Test
    func `Image file types have correct extensions`() throws {
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

    @Test
    func `Error descriptions are user-friendly`() throws {
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

    @Test
    func `File Upload works with different file types`() throws {
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

    @Test
    func `File Upload max size defaults correctly`() throws {
        let fileUpload = try FileUpload(
            fieldName: "document",
            filename: "file.pdf",
            fileType: .pdf
        )

        let expectedSize = Measurement(value: 10, unit: UnitInformationStorage.mebibytes)
        #expect(fileUpload.maxSize == expectedSize)
    }

    @Test
    func `File Upload validates at exact max size`() throws {
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

    @Test
    func `File Upload error equality works`() throws {
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
