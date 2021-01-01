//
//  DiagramViewController+DiagramViewControllerDelegate.swift
//  EP Diagram
//
//  Created by David Mann on 5/31/20.
//  Copyright © 2020 EP Studios. All rights reserved.
//

import UIKit
import CoreImage
import os.log

protocol DiagramViewControllerDelegate: class {
    func selectLadderTemplate(ladderTemplate: LadderTemplate?)
    func saveTemplates(_ templates: [LadderTemplate])
    func selectSampleDiagram(_ diagram: Diagram?)
    func setViewsNeedDisplay()
    func rotateImage(degrees: Double)
    func resetImage()
}

extension DiagramViewController: DiagramViewControllerDelegate {
    // FIXME: need to make this undoable, going back to previous ladder (not just template).  See set diagram.image.
    func selectLadderTemplate(ladderTemplate: LadderTemplate?) {
        os_log("selecteLadderTemplate - ViewController", log: OSLog.action, type: .info)

        if let ladderTemplate = ladderTemplate {
            let ladder = Ladder(template: ladderTemplate)
            setLadder(ladder: ladder)
        }
    }

    private func setLadder(ladder: Ladder) {
        let oldLadder = diagram.ladder
        currentDocument?.undoManager?.registerUndo(withTarget: self, handler: { target in
            target.setLadder(ladder: oldLadder)
        })
        NotificationCenter.default.post(name: .didUndoableAction, object: nil)
        diagram.ladder = ladder
        ladderView.ladder = ladder
        setViewsNeedDisplay()
    }

    func saveTemplates(_ templates: [LadderTemplate]) {
        os_log("saveTemplates()", log: .action, type: .info)
        do {
            try FileIO.store(templates, to: .documents, withFileName: FileIO.userTemplateFile)
        } catch {
            os_log("File error: %s", log: .errors, type: .error, error.localizedDescription)
            Common.showFileError(viewController: self, error: error)
        }
    }

    func selectSampleDiagram(_ diagram: Diagram?) {
        os_log("selectSampleDiagram()", log: .action, type: .info)
        guard let diagram = diagram else { return }
        setDiagram(diagram)
    }

    func setDiagram(_ diagram: Diagram) {
        let oldDiagram = self.diagram
        currentDocument?.undoManager?.registerUndo(withTarget: self, handler: { target in
            target.setDiagram(oldDiagram)
        })
        NotificationCenter.default.post(name: .didUndoableAction, object: nil)
        self.diagram = diagram
        self.imageView.image = diagram.image
        self.imageScrollView.zoomScale = 1.0
        self.ladderView.diagram = diagram
//        self.diagram.calibration.reset()
        setTitle()
        setViewsNeedDisplay()
    }

    func setViewsNeedDisplay() {
        cursorView.setNeedsDisplay()
        ladderView.setNeedsDisplay()
    }

    func rotateImage(degrees: Double) {
        //        UIView.animate(withDuration: 0.5, animations: {
//        let transform: CGAffineTransform = CGAffineTransform(rotationAngle: CGFloat(Common.radians(degrees: degrees)))
//        guard let image = self.imageView.image?.cgImage else { return }
//        let ciImage = CIImage(cgImage: image)
//        let newCiImage = ciImage.transformed(by: transform)
//        let newImage = UIImage(ciImage: newCiImage)
//        self.imageView.image = newImage
        //            self.imageView.image.transform = self.imageView.transform.image.rotated(by: CGFloat(Common.radians(degrees: degrees)))
//        })
        if let image = imageView.image {
            imageView.image = rotateUIImage(image: image, angleRadians: CGFloat(Common.radians(degrees: degrees)))
        }
    }

    func resetImage() {
        UIView.animate(withDuration: 0.5) {
            self.imageView.transform = CGAffineTransform.identity
        }
    }

    // See https://stackoverflow.com/questions/5017540/how-to-i-rotate-uiimageview-by-90-degrees-inside-a-uiscrollview-with-correct-ima
    func rotateUIImage(image: UIImage, angleRadians: CGFloat) -> UIImage {
        let rotatedViewBox = UIView(frame: CGRect(x: 0, y: 0, width: image.size.width, height: image.size.height))
        let transform = CGAffineTransform(rotationAngle: angleRadians)
        rotatedViewBox.transform = transform
        let rotatedSize = rotatedViewBox.frame.size
        UIGraphicsBeginImageContext(rotatedSize)
        let bitmap: CGContext? = UIGraphicsGetCurrentContext()
        bitmap?.translateBy(x: rotatedSize.width/2, y: rotatedSize.height/2)
        bitmap?.rotate(by: angleRadians)
        bitmap?.scaleBy(x: 1.0, y: -1.0)
        guard let cgImage = image.cgImage else { return image }
        bitmap?.draw(cgImage, in: CGRect(x: -image.size.width / 2, y: -image.size.height / 2, width: image.size.width, height: image.size.height))
        let newImage: UIImage? = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return newImage ?? image

    }

//    UIImage* rotateUIImage(const UIImage* src, float angleDegrees)  {
//        UIView* rotatedViewBox = [[UIView alloc] initWithFrame: CGRectMake(0, 0, src.size.width, src.size.height)];
//        float angleRadians = angleDegrees * ((float)M_PI / 180.0f);
//        CGAffineTransform t = CGAffineTransformMakeRotation(angleRadians);
//        rotatedViewBox.transform = t;
//        CGSize rotatedSize = rotatedViewBox.frame.size;
//        [rotatedViewBox release];
//
//        UIGraphicsBeginImageContext(rotatedSize);
//        CGContextRef bitmap = UIGraphicsGetCurrentContext();
//        CGContextTranslateCTM(bitmap, rotatedSize.width/2, rotatedSize.height/2);
//        CGContextRotateCTM(bitmap, angleRadians);
//
//        CGContextScaleCTM(bitmap, 1.0, -1.0);
//        CGContextDrawImage(bitmap, CGRectMake(-src.size.width / 2, -src.size.height / 2, src.size.width, src.size.height), [src CGImage]);
//
//        UIImage *newImage = UIGraphicsGetImageFromCurrentImageContext();
//        UIGraphicsEndImageContext();
//
//        return newImage;
//    }


    

}
