import UIKit
import CoreBluetooth

class  PeripheralViewController: UITableViewCell {
    
    @IBOutlet  weak var peripheralLabel: UILabel!
    
    override func  awakeFromNib() {
        super.awakeFromNib()
    }
    
    override func  setSelected(_ selected:  Bool,  animated: Bool) {
        super.setSelected(selected, animated: animated)
    }
}
