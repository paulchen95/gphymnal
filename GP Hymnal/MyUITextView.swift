import SwiftUI

struct MyUITextView: UIViewRepresentable {
    var hymn: Hymn
    
    func makeUIView(context: UIViewRepresentableContext<MyUITextView>) -> UITextView {
        let myView = UITextView()
        
        var text = self.hymn.text + "\n\n"
        if (hymn.author.count > 0) {
            text.append("Author: " + hymn.author + "\n")
        }
        if (hymn.translator.count > 0) {
            text.append("Translator: " + hymn.translator + "\n")
        }
        if (hymn.composer.count > 0) {
            text.append("Composer: " + hymn.composer + "\n")
        }
        
        myView.text = text
        myView.font = UIFont(name: "GeezaPro", size: 18)
        myView.delegate = context.coordinator
        myView.refreshControl = UIRefreshControl()
        myView.refreshControl?.addTarget(context.coordinator, action: #selector(Coordinator.handleRefresh), for: .valueChanged)
        myView.minimumZoomScale = 0.8
        myView.maximumZoomScale = 5.0
        myView.bounces = true
        myView.bouncesZoom = true
        myView.isEditable = false
        myView.isSelectable = true
        myView.showsVerticalScrollIndicator = false
        myView.showsHorizontalScrollIndicator = false
        myView.refreshControl = nil
        return myView
    }
    
    func updateUIView(_ uiView: UITextView,
                      context: UIViewRepresentableContext<MyUITextView>) {
        // Perform any update tasks if necessary
    }
    
    func makeCoordinator() -> Coordinator {
         Coordinator(self)
    }
    
    class Coordinator: NSObject, UITextViewDelegate {
        var control: MyUITextView

        init(_ control: MyUITextView) {
            self.control = control
        }

        @objc func handleRefresh(sender: UIRefreshControl) {
            sender.endRefreshing()
        }
    }
}

struct MyUIView_Previews: PreviewProvider {
    static var previews: some View {
        MyUITextView(hymn: Hymn(name: "Abide With Me", filename: "AbideWithMe", author: "Henry F. Lyte", translator: "", composer: "William H. Monk", text:
        """
        Abide with me, fast falls the eventide;
        The darkness deepens, Lord, with me abide.
        When other helpers fail and comforts flee,
        Help of the helpless, O, abide with me!

        Swift to its close ebbs out life’s little day;
        Earth’s joys grow dim, its glories pass away;
        Change and decay in all around I see;
        O Thou who changest not, abide with me!

        I need Thy presence ev’ry passing hour;
        What but Thy grace can foil the tempter’s pow’r?
        Who like Thyself my guide and stay can be?
        Through cloud and sunshine, O abide with me!

        I fear no foe with Thee at hand to bless,
        Though ills have weight and tears their bitterness
        Where is death’s sting? Where grave, Thy victory?
        I triumph still, if Thou abide with me.

        Hold Thou Thy cross before my closing eyes;
        Shine through the gloom, and point me to the skies;
        Heaven’s morning breaks and earth’s vain shadows flee;
        In life, in death, O Lord, abide with me!
        """))
    }
}


