import UIKit
import ProgressHUD
import Kingfisher

final class ImagesListViewController: UIViewController {
    
    private let tableView: UITableView = {
        let tableView = UITableView()
        tableView.translatesAutoresizingMaskIntoConstraints = false
        return tableView
    }()

    private var photos: [Photo] = []
    private let imagesListService = ImagesListService()
    private let photosName: [String] = Array(0..<20).map{ "\($0)" }
    private let showSingleImageSegueIdentifier = "ShowSingleImage"

    override func viewDidLoad() {
        super.viewDidLoad()
        createTableViewLayout()
        tableView.register(ImagesListCell.self, forCellReuseIdentifier: "ImagesListCell")
        tableView.contentInset = UIEdgeInsets(top: 16, left: 0, bottom: 16, right: 0 )
        tableView.delegate = self
        tableView.dataSource = self
        
        if photos.count == 0 {
            imagesListService.fetchPhotosNextPage()
        }
        
        NotificationCenter.default.addObserver(
            forName: ImagesListService.DidChangeNotification,
            object: nil,
            queue: .main) { [weak self] _ in
                guard let self else {return}
                self.updateTableViewAnimated()
            }
    }
    
    private func createTableViewLayout() {
        view.addSubview(tableView)
        tableView.backgroundColor = .black
        
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.topAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor)
        ])
    }
    
    private func updateTableViewAnimated() {
        let oldCount = photos.count
        let newCount = imagesListService.photos.count
        photos = imagesListService.photos
        if oldCount != newCount {
            tableView.performBatchUpdates {
                let indexPaths = (oldCount..<newCount).map { i in
                    IndexPath(row: i, section: 0)
                }
                tableView.insertRows(at: indexPaths, with: .automatic)
            } completion: { _ in }
        }
    }
    
    private func presentSingleImageView(for indexPath: IndexPath) {
        guard let url = URL(string: photos[indexPath.row].largeImageURL) else {return}
        let singleImageViewController = SingleImageViewController(fullImageUrl: url)
        singleImageViewController.modalPresentationStyle = .fullScreen
        present(singleImageViewController, animated: true, completion: nil)
    }
}

extension ImagesListViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return photos.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "ImagesListCell", for: indexPath)
        guard let imagesListCell = cell as? ImagesListCell else {
            return UITableViewCell()
        }
        imagesListCell.backgroundColor = .black
        imagesListCell.delegate = self
        configCell(for: imagesListCell, with: indexPath)
        return imagesListCell
    }
}

extension ImagesListViewController {
    func configCell(for cell: ImagesListCell, with indexPath: IndexPath) {
        guard let date = photos[indexPath.row].createdAt else { return }
        let dateString = date.dateTimeString
        
        guard let url = URL(string: photos[indexPath.row].thumbImageURL) else {return}
        cell.cellImage.kf.indicatorType = .activity
        cell.cellImage.kf.setImage(with: url, placeholder: UIImage(named: "placeholder_image")) { [weak self] result in
            guard let self = self else {return}
            switch result {
            case .success(let image):
                cell.configureCellElements(image: image.image, date: dateString, isLiked: photos[indexPath.row].likedByUser)
                self.tableView.reloadRows(at: [indexPath], with: .automatic)
            case .failure(_):
                guard let placeholderImage = UIImage(named: "placeholder_image") else { return }
                cell.configureCellElements(image: placeholderImage, date: "Error", isLiked: false)
            }
        }
        let selectedView = UIView()
        selectedView.backgroundColor = UIColor.lightGray.withAlphaComponent(0.2)
        cell.selectedBackgroundView = selectedView
    }
}

extension ImagesListViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if let cell = tableView.cellForRow(at: indexPath) as? ImagesListCell {
            cell.isSelected = false
        }
        presentSingleImageView(for: indexPath)
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        let image = photos[indexPath.row]
        let imageInsets = UIEdgeInsets(top: 4, left: 16, bottom: 4, right: 16)
        let imageViewWidth = tableView.bounds.width - imageInsets.left - imageInsets.right
        let imageWidth = image.size.width
        let scale = imageViewWidth / imageWidth
        let cellHeight = image.size.height * scale + imageInsets.top + imageInsets.bottom
        return cellHeight
    }
    
    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        guard indexPath.row + 1 == imagesListService.photos.count else { return }
        imagesListService.fetchPhotosNextPage()
    }
}

extension ImagesListViewController: ImagesListCellDelegate {
    func imagesListCellDidTapLike(_ cell: ImagesListCell) {
        guard let indexPath = tableView.indexPath(for: cell) else { return }
        let photo = photos[indexPath.row]
        UIBlockingProgressHUD.show()
        imagesListService.changeLike(photoId: photo.id, isLike: !photo.likedByUser) { [weak self] result in
            guard let self = self else {return}
            switch result {
            case .success:
                DispatchQueue.main.async {
                    self.photos = self.imagesListService.photos
                    cell.setIsLiked(self.photos[indexPath.row].likedByUser)
                    UIBlockingProgressHUD.dismiss()
                }
            case .failure:
                DispatchQueue.main.async {
                    UIBlockingProgressHUD.dismiss()
                    self.showAlertViewController()
                }
            }
        }
    }
    
    private func showAlertViewController() {
        let alertViewController = UIAlertController(
            title: "Что-то пошло не так(",
            message: "Не удалось поставить лайк",
            preferredStyle: .alert)
        let action = UIAlertAction(title: "Ок", style: .default)
        alertViewController.addAction(action)
        present(alertViewController, animated: true)
    }
}
