//
//  Tesseract+Layout.swift
//  
//
//  Created by Winston Chen on 11/3/21.
//

import Foundation
import libtesseract

public typealias PageSegmentationMode = TessPageSegMode
public extension PageSegmentationMode {
  static let osdOnly = PSM_OSD_ONLY
  static let autoOsd = PSM_AUTO_OSD
  static let autoOnly = PSM_AUTO_ONLY
  static let auto = PSM_AUTO
  static let singleColumn = PSM_SINGLE_COLUMN
  static let singleBlockVerticalText = PSM_SINGLE_BLOCK_VERT_TEXT
  static let singleBlock = PSM_SINGLE_BLOCK
  static let singleLine = PSM_SINGLE_LINE
  static let singleWord = PSM_SINGLE_WORD
  static let circleWord = PSM_CIRCLE_WORD
  static let singleCharacter = PSM_SINGLE_CHAR
  static let sparseText = PSM_SPARSE_TEXT
  static let sparseTextOsd = PSM_SPARSE_TEXT_OSD
  static let count = PSM_COUNT
}

public extension Tesseract {
    
    var pageSegmentationMode: PageSegmentationMode {
        get {
            perform { tessPointer in
                TessBaseAPIGetPageSegMode(tessPointer)
            }
        }
        set {
            perform { tessPointer in
                TessBaseAPISetPageSegMode(tessPointer, newValue)
            }
        }
    }
    
    func analyseLayout(on data: Data) -> [RecognizedBlock] {
        return perform { tessPointer -> [RecognizedBlock] in
            var pix = createPix(from: data)
            defer { pixDestroy(&pix) }
            TessBaseAPISetImage2(tessPointer, pix)
            if TessBaseAPIGetSourceYResolution(tessPointer) < 70 {
                TessBaseAPISetSourceResolution(tessPointer, 300)
            }
            guard TessBaseAPIAnalyseLayout(tessPointer) != nil else {
                print("Tesseract: Error Analyzing Layout")
                return []
            }
            let results = recognizedLayoutBlocks(with: tessPointer)
            do {
                let blocks = try results.get()
                return blocks
            } catch {
                print("Error retrieving the value: \(error)")
                return []
            }
        }
    }
    
    private func recognizedLayoutBlocks(with pointer: TessBaseAPI) -> Result<[RecognizedBlock], Error> {
        guard let resultIterator = TessBaseAPIGetIterator(pointer)
            else { return .failure(Tesseract.Error.unableToRetrieveIterator) }
        defer { TessPageIteratorDelete(resultIterator) }
        var results = [RecognizedBlock]()
        repeat {
            var box = BoundingBox()
            TessPageIteratorBoundingBox(resultIterator, .block, &box.left, &box.top, &box.right, &box.bottom)
            results.append(RecognizedBlock(text: "", boundingBox: box, confidence: 0))
        } while (TessPageIteratorNext(resultIterator, .block) > 0)
        return .success(results)
    }
}
