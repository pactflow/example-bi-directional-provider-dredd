const Product = require("./product");
const ProductRepository = require("./product.repository");

const repository = new ProductRepository();

exports.create = async (req, res) => {
    const data = req.body
    const product = new Product(data.id, data.type, data.name, data.version, data.price)
    await repository.create(product)
    product ? res.send(product) : res.status(400).send({message: "invalid product"})
};
exports.getAll = async (req, res) => {
    res.send(await repository.fetchAll())
};
exports.getById = async (req, res) => {
    const product = await repository.getById(req.params.id);
    product ? res.send(product) : res.status(404).send({message: "Product not found"})
};
exports.deleteById = async (req, res) => {
    const product = await repository.deleteById(req.params.id);
    product ? res.send(product) : res.status(404).send({message: "Product not found"}) // Maybe not the correct line here
};

exports.repository = repository;