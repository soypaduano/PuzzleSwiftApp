//  PuzzleGame
//
//  Created by Desarrollo MAC on 7/2/18.
//

import UIKit

extension UIImage {
    var topHalf: UIImage? {
        guard let cgImage = cgImage, let image = cgImage.cropping(to: CGRect(origin: .zero, size: CGSize(width: size.width, height: size.height/2))) else { return nil }
        return UIImage(cgImage: image, scale: scale, orientation: imageOrientation)
    }
    var bottomHalf: UIImage? {
        guard let cgImage = cgImage, let image = cgImage.cropping(to: CGRect(origin: CGPoint(x: 0,  y: CGFloat(Int(size.height)-Int(size.height/2))), size: CGSize(width: size.width, height: CGFloat(Int(size.height) - Int(size.height/2))))) else { return nil }
        return UIImage(cgImage: image, scale: scale, orientation: imageOrientation)
    }
    var leftHalf: UIImage? {
        guard let cgImage = cgImage, let image = cgImage.cropping(to: CGRect(origin: .zero, size: CGSize(width: size.width/2, height: size.height))) else { return nil }
        return UIImage(cgImage: image, scale: scale, orientation: imageOrientation)
    }
    var rightHalf: UIImage? {
        guard let cgImage = cgImage, let image = cgImage.cropping(to: CGRect(origin: CGPoint(x: CGFloat(Int(size.width)-Int((size.width/2))), y: 0), size: CGSize(width: CGFloat(Int(size.width)-Int((size.width/2))), height: size.height)))
            else { return nil }
        return UIImage(cgImage: image, scale: scale, orientation: imageOrientation)
    }
    var splitedInFourParts: [UIImage] {
        guard case let topHalf = topHalf,
            case let bottomHalf = bottomHalf,
            let topLeft = topHalf?.leftHalf,
            let topRight = topHalf?.rightHalf,
            let bottomLeft = bottomHalf?.leftHalf,
            let bottomRight = bottomHalf?.rightHalf else{ return [] }
        return [topLeft, topRight, bottomLeft, bottomRight]
    }
    var splitedInSixteenParts: [UIImage] {
        var array = splitedInFourParts.flatMap({$0.splitedInFourParts})
        // if you need it in reading order you need to swap some image positions
        array.swapAt(2, 4)
        array.swapAt(3, 5)
        array.swapAt(10, 12)
        array.swapAt(11, 13)
        return array
    }
}

class ViewController: UIViewController, UINavigationControllerDelegate, UIImagePickerControllerDelegate {
    @IBOutlet weak var bigImage: UIImageView!
    @IBOutlet weak var board: UIView!
    @IBOutlet weak var lb_counter: UILabel!
    @IBOutlet weak var lb_record: UILabel!
    @IBOutlet weak var lb_won: UILabel!
    @IBOutlet weak var btn_again: UIButton!
    @IBOutlet weak var btn_changeImage: UIButton!
    @IBOutlet weak var btn_other: UIButton!
    
    
    var firstBoardPosition : CGPoint = CGPoint(x: 0, y: 0)
    private var tileWidth : CGFloat = 0.0
    private var tileCenterX : CGFloat = 0.0
    private var tileCenterY : CGFloat = 0.0
    private var tileArray : NSMutableArray = []
    private var tileCenterArray : NSMutableArray = []
    private var tileNumber : Int = 0
    var tileEmptyCenter : CGPoint = CGPoint(x: 0.0, y: 0.0)
    var counter = 0
    var touchesCount = 0
    
    var picker : UIImagePickerController = UIImagePickerController()
    var newPic = false
    
    //Variables for the crop image
    var cropImages: [UIImage] = []
    @IBOutlet weak var imageToCrop: UIImageView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        lb_counter.text = "Touches: 0"
        SetBordersToView()
        GetRecord()
        btn_again.isHidden = true
        lb_won.isHidden = true
    }
    
    private func SetRecord(record: Int){
        if(record < UserDefaults.standard.integer(forKey: "Record")){
            UserDefaults.standard.set(record, forKey: "Record")
            lb_record.text = "High: " + String(record)
        }
    }
    
    private func GetRecord(){
        lb_record.text = "High: " +  String(UserDefaults.standard.integer(forKey: "Record"))
    }
    
    private func SetBordersToView(){
        board.layer.borderColor = UIColor.black.cgColor
        board.layer.borderWidth = 1
        imageToCrop.layer.borderWidth = 1
        imageToCrop.layer.borderColor = UIColor.black.cgColor
    }
    
    override func viewDidAppear(_ animated: Bool) {
        if(!newPic){
            cropImages = (imageToCrop.image?.splitedInSixteenParts)!
            SetBoard()
            randomTiles()
            newPic = true
        }
        firstBoardPosition = board.center
    }

    func checkPositions() -> Bool{
        var win : Bool = false
        for tiles in tileArray{
            let tile = tiles as! CustomImage
            if(tile.firstOrigin == tile.originCenter){
                win = true
            } else {
                win = false
                return win
            }
        }
        return win
    }
    
    @IBAction func playAgain(_ sender: Any) {
        tileNumber = 0
        board.subviews.forEach({ $0.removeFromSuperview() })
        backToPosition()
        SetBoard()
        randomTiles()
    }
    
    @IBAction func btn_restart(_ sender: Any) {
        randomTiles()
        touchesCount = 0
        lb_counter.text = "Touches: " + String(touchesCount)
    }
    
    private func SetBoard(){
        tileArray = []
        tileCenterArray = []
        let boardWidth = self.board.frame.width // ancho del tablero
        self.tileWidth = boardWidth / 4   // ancho de cada cuadro para que puedan entrar 4 cuadros por cada fila
        self.tileCenterX = self.tileWidth / 2
        self.tileCenterY = self.tileWidth / 2
        
        for _ in 0..<4{
            for _ in 0..<4{
                let tileFrame : CGRect = CGRect(x: 0, y: 0, width: self.tileWidth, height: self.tileWidth)
                let tileImage : CustomImage = CustomImage(image: cropImages[tileNumber])
                tileImage.frame = tileFrame
                let currentCenter : CGPoint = CGPoint(x: self.tileCenterX, y: self.tileCenterY) //Centro actual de la tile
                tileImage.center = currentCenter
                tileImage.firstOrigin = currentCenter
                tileImage.originCenter = currentCenter
                tileImage.id = tileNumber
                self.board.addSubview(tileImage)
                self.tileArray.add(tileImage) ///La añadimos al array de Tiles
                self.tileCenterArray.add(currentCenter) //Añadimos su centro, al array de centros de Tiles
                tileNumber += 1 //Sumamos uno
                self.tileCenterX = self.tileCenterX + self.tileWidth //Y en las posiciones horizontales, sumamos uno
                tileImage.isUserInteractionEnabled = true
            }
            self.tileCenterX = self.tileWidth / 2 //Volvemos a posicionar el origen horizontal
            self.tileCenterY = self.tileCenterY + self.tileWidth //Asignamos la Y para que baje
        }
        
        //Eliminamos la ultima posicion
        let lastImageTile : CustomImage = tileArray.lastObject as!  CustomImage
        lastImageTile.removeFromSuperview()
        tileArray.removeLastObject()
    }
    
    private func randomTiles(){
        let tempTileCenterArray : NSMutableArray =  tileCenterArray.mutableCopy() as! NSMutableArray //Creamos un array temporal
        for anyTile in tileArray {
            let randomIndex : Int = Int(arc4random()) % tempTileCenterArray.count //Buscamos un numero random entre el array temporal
            let randomCenter : CGPoint = tempTileCenterArray[randomIndex] as! CGPoint //Cogemos el centro de esa tile random
            (anyTile as! CustomImage).center = randomCenter //Y vamos tile a tile moviendolas hacia el centro random
            (anyTile as! CustomImage).originCenter = randomCenter
            tempTileCenterArray.removeObject(at: randomIndex) //Y borramos esa tile random que hayamos cogido
        }
        
        tileEmptyCenter = tempTileCenterArray[0] as! CGPoint //Una ve recorre todo el array, la tile Empty es la posicion 0.
        /* Es la posicion 0 ya que el array se queda con un solo elemento, es decir, el vacio, el ultimo.  */
    }
    
    private func ReOrganize(){
        for tiles in tileArray{
            let tile = tiles as! CustomImage
            tile.originCenter = tile.firstOrigin
        }
    }

    private func AddOne(){
        touchesCount += 1
        lb_counter.text = "Touches: " + String(touchesCount)
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        let currentTouch : UITouch = touches.first!
        if(self.tileArray.contains(currentTouch.view as Any)){
            let touchImage : CustomImage = currentTouch.view as! CustomImage //Cogemos el label que ha sido tocado
            let xDif : CGFloat = touchImage.center.x - tileEmptyCenter.x //Calculamos la diferencia entre el label y la posicion vacia. (En x)
            let yDif: CGFloat = touchImage.center.y - tileEmptyCenter.y //Calculamos la diferencia entre el label y la posicion vacia. (En y)
            let distance : CGFloat = sqrt(pow(xDif, 2) + pow(yDif, 2)) //Calculamos su distancia con la resta y raiz cuadrada entre vectores
            if(Int(distance) == Int(tileWidth)){ //Si la distancia es correcta... (Lo hacemos int ya que comparar floats no es fiable)
                let tempCenter : CGPoint = touchImage.center //Cogemos la posicion del label que ha sido tocado
                UIView.beginAnimations(nil, context: nil)
                UIView.setAnimationDuration(0.2)
                touchImage.center = tileEmptyCenter //Ponemos el label en la posicion vacia
                touchImage.originCenter = tileEmptyCenter
                UIView.commitAnimations()
                tileEmptyCenter = tempCenter //Y ponemos la posicion vacia en el label que acaba de ser tocado.
                AddOne()
                
            } else {
                print("Invalid movement")
            }
            
            if(checkPositions()){ //USER WIN
                SetRecord(record: touchesCount)
                WinMovement()
            }
        }
    }
    
    private func backToPosition(){
        lb_won.isHidden = true
        btn_again.isHidden = true
        btn_other.isHidden = false
        btn_changeImage.isHidden = false
        UIView.beginAnimations(nil, context: nil)
        UIView.setAnimationDuration(1)
        board.center = firstBoardPosition
        UIView.commitAnimations()
    }
    
    private func WinMovement(){
        btn_other.isHidden = true
        btn_changeImage.isHidden = true
        lb_won.isHidden = false
        btn_again.isHidden = false
        UIView.beginAnimations(nil, context: nil)
        UIView.setAnimationDuration(1)
        board.center = imageToCrop.center
        UIView.commitAnimations()
    }
    

    @IBAction func changeImageBtn(_ sender: Any) {
        picker.delegate = self
        picker.sourceType = .photoLibrary
        present(picker, animated: true, completion: nil)
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        picker.dismiss(animated: true, completion: nil)
        tileNumber = 0
        touchesCount = 0
        imageToCrop.image = info[UIImagePickerControllerOriginalImage] as? UIImage
        board.subviews.forEach({ $0.removeFromSuperview() })
        cropImages = (imageToCrop.image?.splitedInSixteenParts)!
        SetBoard()
        randomTiles()
    }
    
}

//ESTAMOS CREANDO UNA CLASE PARA PODER GUARDAR EL CG POINT DE CADA UNO
class CustomImage : UIImageView {
    var id : Int = 0
    var firstOrigin : CGPoint = CGPoint(x: 0, y: 0)
    var originCenter : CGPoint = CGPoint(x: 0, y: 0)
}


